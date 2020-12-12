require 'yaml'
require 'json'
require 'tmpdir'

require 'chake/config'
require 'chake/version'
require 'chake/readline'

desc 'Initializes current directory with sample structure'
task init: 'init:itamae'
Chake::ConfigManager.all.map do |cfgmgr|
  desc "Initializes current directory for #{cfgmgr.short_name}"
  task "init:#{cfgmgr.short_name}" do
    cfgmgr.init
  end
end

desc 'list nodes'
task :nodes do
  fields = %i[hostname connection config_manager]
  IO.popen(['column', '-t'], mode: 'w') do |table|
    table.puts(fields.join(' '))
    table.puts(fields.map { |f| '-' * f.length }.join(' '))
    Chake.nodes.each do |node|
      table.puts fields.map { |f| node.send(f) }.join(' ')
    end
  end
end

def encrypted_for(node)
  encrypted_files = Dir.glob("**/files/{default,host-#{node}}/*.{asc,gpg}") + Dir.glob('**/files/*.{asc,gpg}')
  encrypted_files.each_with_object({}) do |key, hash|
    hash[key] = key.sub(/\.(asc|gpg)$/, '')
  end
end

def if_files_changed(node, group_name, files)
  return if files.empty?

  hash_io = IO.popen(%w[xargs sha1sum], 'w+')
  files.sort.each { |f| hash_io.puts(f) }
  hash_io.close_write
  current_hash = hash_io.read

  hash_file = File.join(Chake.tmpdir, "#{node}.#{group_name}.sha1sum")
  hash_on_disk = nil
  hash_on_disk = File.read(hash_file) if File.exist?(hash_file)

  yield if current_hash != hash_on_disk
  FileUtils.mkdir_p(File.dirname(hash_file))
  File.open(hash_file, 'w') do |f|
    f.write(current_hash)
  end
end

def write_json_file(file, data)
  File.chmod(0o600, file) if File.exist?(file)
  File.open(file, 'w', 0o600) do |f|
    f.write(JSON.pretty_generate(data))
    f.write("\n")
  end
end

desc 'Executed before bootstrapping'
task bootstrap_common: :connect_common

desc 'Executed before uploading'
task upload_common: :connect_common

desc 'Executed before uploading'
task converge_common: :connect_common

desc 'Executed before connecting to any host'
task :connect_common

Chake.nodes.each do |node|
  node.silent = Rake.application.options.silent

  hostname = node.hostname

  bootstrap_script = File.join(Chake.tmpdir, "#{hostname}.bootstrap")

  bootstrap_steps = node.bootstrap_steps

  bootstrap_code = (["#!/bin/sh\n", "set -eu\n"] + bootstrap_steps.map { |f| File.read(f) }).join

  desc "bootstrap #{hostname}"
  task "bootstrap:#{hostname}" => :bootstrap_common do
    mkdir_p Chake.tmpdir unless File.directory?(Chake.tmpdir)
    if node.needs_bootstrap? && (!File.exist?(bootstrap_script) || File.read(bootstrap_script) != bootstrap_code)

      # create bootstrap script
      File.open(bootstrap_script, 'w') do |f|
        f.write(bootstrap_code)
      end
      chmod 0o755, bootstrap_script

      # copy bootstrap script over
      scp = node.scp
      target = "/tmp/.chake-bootstrap.#{Etc.getpwuid.name}"
      sh *scp, bootstrap_script, node.scp_dest + target

      # run bootstrap script
      node.run_as_root("#{target} #{hostname}")
    end

    # overwrite config with current contents
    config = File.join(Chake.tmpdir, "#{hostname}.json")
    write_json_file(config, node.data)
  end

  desc "upload data to #{hostname}"
  task "upload:#{hostname}" => :upload_common do
    next unless node.needs_upload?

    encrypted = encrypted_for(hostname)
    rsync_excludes = (encrypted.values + encrypted.keys).map { |f| ['--exclude', f] }.flatten
    rsync_excludes << '--exclude' << '.git/'
    rsync_excludes << '--exclude' << 'cache/'
    rsync_excludes << '--exclude' << 'nodes/'
    rsync_excludes << '--exclude' << 'local-mode-cache/'

    rsync = node.rsync + ['-avp'] + ENV.fetch('CHAKE_RSYNC_OPTIONS', '').split
    rsync_logging = Rake.application.options.silent && '--quiet' || '--verbose'

    hash_files = Dir.glob(File.join(Chake.tmpdir, '*.sha1sum'))
    files = Dir.glob('**/*').reject { |f| File.directory?(f) } - encrypted.keys - encrypted.values - hash_files
    if_files_changed(hostname, 'plain', files) do
      sh *rsync, '--delete', rsync_logging, *rsync_excludes, './', node.rsync_dest
    end

    if_files_changed(hostname, 'enc', encrypted.keys) do
      Dir.mktmpdir do |tmpdir|
        encrypted.each do |encrypted_file, target_file|
          target = File.join(tmpdir, target_file)
          mkdir_p(File.dirname(target))
          rm_f target
          File.open(target, 'w', 0o400) do |output|
            IO.popen(['gpg', '--quiet', '--batch', '--use-agent', '--decrypt', encrypted_file]) do |data|
              output.write(data.read)
            end
          end
          puts "#{target} (decrypted)"
        end
        sh *rsync, rsync_logging, "#{tmpdir}/", node.rsync_dest
      end
    end
  end

  converge_dependencies = [:converge_common, "bootstrap:#{hostname}", "upload:#{hostname}"]

  desc "converge #{hostname}"
  task "converge:#{hostname}" => converge_dependencies do
    node.converge
  end

  desc 'apply <recipe> on #{hostname}'
  task "apply:#{hostname}", [:recipe] => %i[recipe_input connect_common] do |_task, _args|
    node.apply($recipe_to_apply)
  end
  task "apply:#{hostname}" => converge_dependencies

  desc "run a command on #{hostname}"
  task "run:#{hostname}", [:command] => %i[run_input connect_common] do
    node.run($cmd_to_run)
  end

  desc "Logs in to a shell on #{hostname}"
  task "login:#{hostname}" => :connect_common do
    node.run_shell
  end

  desc 'checks connectivity and setup on all nodes'
  task "check:#{hostname}" => :connect_common do
    node.run('sudo echo OK')
  end
end

task :run_input, :command do |_task, args|
  $cmd_to_run = args[:command]
  unless $cmd_to_run
    puts '# Enter command to run (use arrow keys for history):'
    $cmd_to_run = Chake::Readline::Commands.readline
  end
  if !$cmd_to_run || $cmd_to_run.strip == ''
    puts
    puts 'I: no command provided, operation aborted.'
    exit(1)
  end
end

task :recipe_input, :recipe do |_task, args|
  $recipe_to_apply = args[:recipe]

  unless $recipe_to_apply
    recipes = Dir['**/*/recipes/*.rb'].map do |f|
      f =~ %r{(.*/)?(.*)/recipes/(.*).rb$}
      cookbook = Regexp.last_match(2)
      recipe = Regexp.last_match(3)
      recipe = nil if recipe == 'default'
      [cookbook, recipe].compact.join('::')
    end.sort
    puts 'Available recipes:'

    IO.popen('column', 'w') do |column|
      column.puts(recipes)
    end

    $recipe_to_apply = Chake::Readline::Recipes.readline
    if !$recipe_to_apply || $recipe_to_apply.empty?
      puts
      puts 'I: no recipe provided, operation aborted.'
      exit(1)
    end
    unless recipes.include?($recipe_to_apply)
      abort "E: no such recipe: #{$recipe_to_apply}"
    end
  end
end

desc 'upload to all nodes'
multitask upload: Chake.nodes.map { |node| "upload:#{node.hostname}" }

desc 'bootstrap all nodes'
multitask bootstrap: Chake.nodes.map { |node| "bootstrap:#{node.hostname}" }

desc 'converge all nodes (default)'
multitask 'converge' => Chake.nodes.map { |node| "converge:#{node.hostname}" }

desc 'Apply <recipe> on all nodes'
multitask 'apply', [:recipe] => Chake.nodes.map { |node| "apply:#{node.hostname}" }

desc 'run <command> on all nodes'
multitask :run, [:command] => Chake.nodes.map { |node| "run:#{node.hostname}" }

task default: :converge

desc 'checks connectivity and setup on all nodes'
multitask check: (Chake.nodes.map { |node| "check:#{node.hostname}" }) do
  puts '✓ all hosts OK'
  puts '  - ssh connection works'
  puts '  - password-less sudo works'
end

desc 'runs a Ruby console in the chake environment'
task :console do
  require 'irb'
  IRB.setup('__FILE__', argv: [])
  workspace = IRB::WorkSpace.new(self)

  puts 'chake - interactive console'
  puts '---------------------------'
  puts 'all node data in available in Chake.nodes'
  puts
  IRB::Irb.new(workspace).run(IRB.conf)
end
