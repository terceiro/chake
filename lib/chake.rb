# encoding: UTF-8

require 'yaml'
require 'json'
require 'tmpdir'

require 'chake/version'
require 'chake/node'
require 'chake/readline'

nodes_file = ENV['CHAKE_NODES'] || 'nodes.yaml'
nodes_directory = ENV['CHAKE_NODES_D'] || 'nodes.d'
node_data = File.exists?(nodes_file) && YAML.load_file(nodes_file) || {}
Dir.glob(File.join(nodes_directory, '*.yaml')).sort.each do |f|
  node_data.merge!(YAML.load_file(f))
end
$nodes = node_data.map { |node,data| Chake::Node.new(node, data) }.reject(&:skip?).uniq(&:hostname)
$chake_tmpdir = ENV.fetch('CHAKE_TMPDIR', 'tmp/chake')

desc "Initializes current directory with sample structure"
task :init do
  if File.exists?('nodes.yaml')
    puts '[exists] nodes.yaml'
  else
    File.open('nodes.yaml', 'w') do |f|
      sample_nodes = <<EOF
host1.mycompany.com:
  run_list:
    - recipe[basics]
EOF
      f.write(sample_nodes)
      puts "[create] nodes.yaml"
    end
  end

  if File.exist?('nodes.d')
    puts '[exists] nodes.d/'
  else
    FileUtils.mkdir_p 'nodes.d'
    puts '[ mkdir] nodes.d/'
  end


  if File.exists?('config.rb')
    puts '[exists] config.rb'
  else
    File.open('config.rb', 'w') do |f|
      f.puts "root = File.expand_path(File.dirname(__FILE__))"
      f.puts "file_cache_path   root + '/cache'"
      f.puts "cookbook_path     root + '/cookbooks'"
      f.puts "role_path         root + '/config/roles'"
    end
    puts "[create] config.rb"
  end

  if !File.exist?('config/roles')
    FileUtils.mkdir_p 'config/roles'
    puts  '[ mkdir] config/roles'
  end
  if !File.exist?('cookbooks/basics/recipes')
    FileUtils.mkdir_p 'cookbooks/basics/recipes/'
    puts  '[ mkdir] cookbooks/basics/recipes/'
  end
  recipe = 'cookbooks/basics/recipes/default.rb'
  if File.exists?(recipe)
    puts "[exists] #{recipe}"
  else
    File.open(recipe, 'w') do |f|
      f.puts "package 'openssh-server'"
    end
    puts "[create] #{recipe}"
  end
  if File.exists?('Rakefile')
    puts '[exists] Rakefile'
  else
    File.open('Rakefile', 'w') do |f|
      f.puts 'require "chake"'
      puts '[create] Rakefile'
    end
  end
end

desc 'list nodes'
task :nodes do
  $nodes.each do |node|
    puts "%-40s %-5s\n" % [node.hostname, node.backend]
  end
end

def encrypted_for(node)
  encrypted_files = Dir.glob("**/files/{default,host-#{node}}/*.{asc,gpg}") + Dir.glob("**/files/*.{asc,gpg}")
  encrypted_files.inject({}) do |hash, key|
    hash[key] = key.sub(/\.(asc|gpg)$/, '')
    hash
  end
end

def if_files_changed(node, group_name, files)
  if files.empty?
    return
  end
  hash_io = IO.popen(['xargs', 'sha1sum'], 'w+')
  files.sort.each { |f| hash_io.puts(f) }
  hash_io.close_write
  current_hash = hash_io.read

  hash_file = File.join($chake_tmpdir, node + '.' + group_name + '.sha1sum')
  hash_on_disk = nil
  if File.exists?(hash_file)
    hash_on_disk = File.read(hash_file)
  end

  if current_hash != hash_on_disk
    yield
  end
  FileUtils.mkdir_p(File.dirname(hash_file))
  File.open(hash_file, 'w') do |f|
    f.write(current_hash)
  end
end


def write_json_file(file, data)
  File.open(file, 'w') do |f|
    f.write(JSON.pretty_generate(data))
    f.write("\n")
  end
end

bootstrap_steps = Dir.glob(File.expand_path('chake/bootstrap/*.sh', File.dirname(__FILE__))).sort

desc 'Executed before bootstrapping'
task :bootstrap_common

desc 'Executed before uploading'
task :upload_common

desc 'Executed before uploading'
task :converge_common

$nodes.each do |node|

  hostname = node.hostname
  bootstrap_script = File.join($chake_tmpdir, 'bootstrap-' + hostname)

  file bootstrap_script => bootstrap_steps do |t|
    mkdir_p(File.dirname(bootstrap_script))
    File.open(t.name, 'w') do |f|
      f.puts '#!/bin/sh'
      f.puts 'set -eu'
      bootstrap_steps.each do |platform|
        f.puts(File.read(platform))
      end
    end
    chmod 0755, t.name
  end

  desc "bootstrap #{hostname}"
  task "bootstrap:#{hostname}" => [:bootstrap_common, bootstrap_script] do
    config = File.join($chake_tmpdir, hostname + '.json')

    if File.exists?(config)
      # already bootstrapped, just overwrite
      write_json_file(config, node.data)
    else
      # copy bootstrap script over
      scp = node.scp
      target = "/tmp/.chake-bootstrap.#{Etc.getpwuid.name}"
      sh *scp, bootstrap_script, node.scp_dest + target

      # run bootstrap script
      node.run_as_root("#{target} #{hostname}")

      # overwrite config with current contents
      mkdir_p File.dirname(config)
      write_json_file(config, node.data)
    end

  end

  desc "upload data to #{hostname}"
  task "upload:#{hostname}" => :upload_common do
    encrypted = encrypted_for(hostname)
    rsync_excludes = (encrypted.values + encrypted.keys).map { |f| ["--exclude", f] }.flatten
    rsync_excludes << "--exclude" << ".git/"
    rsync_excludes << "--exclude" << "cache/"

    rsync = node.rsync + ["-avp"] + ENV.fetch('CHAKE_RSYNC_OPTIONS', '').split
    rsync_logging = Rake.application.options.silent && '--quiet' || '--verbose'

    hash_files = Dir.glob(File.join($chake_tmpdir, '*.sha1sum'))
    files = Dir.glob("**/*").select { |f| !File.directory?(f) } - encrypted.keys - encrypted.values - hash_files
    if_files_changed(hostname, 'plain', files) do
      sh *rsync, '--delete', rsync_logging, *rsync_excludes, './', node.rsync_dest
    end

    if_files_changed(hostname, 'enc', encrypted.keys) do
      Dir.mktmpdir do |tmpdir|
        encrypted.each do |encrypted_file, target_file|
          target = File.join(tmpdir, target_file)
          mkdir_p(File.dirname(target))
          sh 'gpg', '--quiet', '--batch', '--use-agent', '--output', target, '--decrypt', encrypted_file
        end
        sh *rsync, rsync_logging, tmpdir + '/', node.rsync_dest
      end
    end
  end

  desc "converge #{hostname}"
  task "converge:#{hostname}" => [:converge_common, "bootstrap:#{hostname}", "upload:#{hostname}"] do
    chef_logging = Rake.application.options.silent && '-l fatal' || ''
    node.run_as_root "chef-solo -c #{node.path}/config.rb #{chef_logging} -j #{node.path}/#{$chake_tmpdir}/#{hostname}.json"
  end

  desc "run a command on #{hostname}"
  task "run:#{hostname}" => 'run_input' do
    node.run($cmd)
  end

  desc "Logs in to a shell on #{hostname}"
  task "login:#{hostname}" do
    node.run_shell
  end

  desc 'checks connectivity and setup on all nodes'
  task "check:#{hostname}" do
    node.run('sudo true')
  end

end

task :run_input do
  puts "# Enter command to run (use arrow keys for history):"
  $cmd = ENV['CMD'] || Chake::Readline.readline
  if !$cmd || $cmd.strip == ''
    puts
    puts "I: no command provided, operation aborted."
    exit(1)
  end
end

desc "upload to all nodes"
task :upload => $nodes.map { |node| "upload:#{node.hostname}" }

desc "bootstrap all nodes"
task :bootstrap => $nodes.map { |node| "bootstrap:#{node.hostname}" }

desc "converge all nodes (default)"
task "converge" => $nodes.map { |node| "converge:#{node.hostname}" }

desc "run a command on all nodes"
task :run => $nodes.map { |node| "run:#{node.hostname}" }

task :default => :converge

desc 'checks connectivity and setup on all nodes'
task :check => ($nodes.map { |node| "check:#{node.hostname}" }) do
  puts "✓ all hosts OK"
end
