# encoding: UTF-8

require 'yaml'
require 'json'
require 'tmpdir'
require 'readline'

require 'chake/node'

nodes_file = ENV['NODES'] || 'nodes.yaml'
node_data = File.exists?(nodes_file) && YAML.load_file(nodes_file) || {}
$nodes = node_data.map { |node,data| Chake::Node.new(node, data) }.reject(&:skip?).uniq(&:hostname)


desc "Initializes current directory with sample structure"
task :init do
  if File.exists?('nodes.yaml')
    puts '[exists] nodes.yaml'
  else
    File.open('nodes.yaml', 'w') do |f|
      sample_nodes = <<EOF
host1.my.tld:
  run_list:
    - recipe[myhost]
EOF
      f.write(sample_nodes)
      puts "[create] nodes.yaml"
    end
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
  if !File.exist?('cookbooks/myhost/recipes')
    FileUtils.mkdir_p 'cookbooks/myhost/recipes/'
    puts  '[ mkdir] cookbooks/myhost/recipes/'
  end
  recipe = 'cookbooks/myhost/recipes/default.rb'
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
  Dir.glob("**/files/{default,host-#{node}}/*.{asc,gpg}").inject({}) do |hash, key|
    hash[key] = key.sub(/\.(asc|gpg)$/, '')
    hash
  end
end

def if_files_changed(node, group_name, files)
  if files.empty?
    return
  end
  hash = IO.popen(['sha1sum', *files]).read
  hash_file = File.join('.tmp', node + '.' + group_name + '.sha1sum')
  if !File.exists?(hash_file) || File.read(hash_file) != hash
    yield
  end
  File.open(hash_file, 'w') do |f|
    f.write(hash)
  end
end

$nodes.each do |node|

  hostname = node.hostname

  desc "bootstrap #{hostname}"
  task "bootstrap:#{hostname}" do
    mkdir_p '.tmp', :verbose => false
    config = '.tmp/' + hostname + '.json'

    seen_before = File.exists?(config)

    unless seen_before
      node.run_as_root('apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -q -y install rsync chef && update-rc.d chef-client disable && service chef-client stop')
      # overwrite config with current contents
      File.open(config, 'w') do |f|
        json_data = node.data
        f.write(JSON.dump(json_data))
        f.write("\n")
      end
    end

  end

  desc "upload data to #{hostname}"
  task "upload:#{hostname}" do
    encrypted = encrypted_for(hostname)
    rsync_excludes = (encrypted.values + encrypted.keys).map { |f| ["--exclude", f] }.flatten

    rsync = "rsync", "-avp", "--exclude", ".git/"
    rsync_logging = Rake.application.options.silent && '--quiet' || '--verbose'

    files = Dir.glob("**/*").select { |f| !File.directory?(f) } - encrypted.keys - encrypted.values
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
  task "converge:#{hostname}" => ["bootstrap:#{hostname}", "upload:#{hostname}"] do
    chef_logging = Rake.application.options.silent && '-l fatal' || ''
    node.run_as_root "chef-solo -c #{node.path}/config.rb #{chef_logging} -j #{node.path}/.tmp/#{hostname}.json"
  end

  desc "run a command on #{hostname}"
  task "run:#{hostname}" => 'run_input' do
    node.run($cmd)
  end
end

task :run_input do
  $cmd = ENV['CMD'] || Readline.readline('$ ')
end

desc "upload to all nodes"
task :upload => $nodes.map { |node| "upload:#{node.hostname}" }

desc "bootstrap all nodes"
task :bootstrap => $nodes.map { |node| "bootstrap:#{node.hostname}" }

desc "converge all nodes (default)"
task "converge" => $nodes.map { |node| "converge:#{node.hostname}" }

task "run a command on all nodes"
task :run => $nodes.map { |node| "run:#{node.hostname}" }

task :default => :converge
