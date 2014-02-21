# encoding: UTF-8

require 'yaml'
require 'json'
require 'tmpdir'
require 'readline'

$nodes_file = ENV['NODES'] || 'nodes.yaml'
$node_data = File.exists?($nodes_file) && YAML.load_file($nodes_file) || {}
$nodes = $node_data.keys

$sample_nodes = <<EOF
host1.my.tld:
  run_list:
    - recipe[myhost]
EOF

desc "Initializes current directory with sample structure"
task :init do
  if !File.exists?('nodes.yaml')
    File.open('nodes.yaml', 'w') do |f|
      f.write($sample_nodes)
      puts "→ nodes.yaml"
    end
  end
  if !File.exists?('config.rb')
    File.open('config.rb', 'w') do |f|
      f.puts "root = File.expand_path(File.dirname(__FILE__))"
      f.puts "file_cache_path   root + '/cache'"
      f.puts "cookbook_path     root + '/cookbooks'"
      f.puts "role_path         root + '/config/roles'"
    end
    puts "→ config.rb"
  end
  mkdir_p 'config/roles'
  mkdir_p 'cookbooks/myhost/recipes/'
  recipe = 'cookbooks/myhost/recipes/default.rb'
  if !File.exists?(recipe)
    File.open(recipe, 'w') do |f|
      f.puts "package 'openssh-server'"
    end
    puts "→ #{recipe}"
    end
end

desc 'list nodes'
task :nodes do
  puts $nodes
end

def encrypted_for(node)
  Dir.glob("**/files/{default,#{node}}/*.{asc,gpg}").inject({}) do |hash, key|
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

  desc "bootstrap #{node}"
  task "bootstrap:#{node}" do
    mkdir_p '.tmp', :verbose => false
    config = '.tmp/' + node + '.json'

    seen_before = File.exists?(config)

    # overwrite config with current contents
    File.open(config, 'w') do |f|
      json_data = $node_data[node]
      f.write(JSON.dump(json_data))
      f.write("\n")
    end

    unless seen_before
      begin
        sh "ssh root@#{node} 'apt-get -q -y install rsync chef'"
      rescue
        rm_f config
        raise
      end
    end

  end

  desc "upload data to #{node}"
  task "upload:#{node}" do
    encrypted = encrypted_for(node)
    excludes = encrypted.values.map { |f| "--exclude #{f}" }.join(' ')

    rsync = "rsync -avp --delete --exclude .git/ #{excludes}"

    Dir.mktmpdir do |tmpdir|
      sh "#{rsync} --quiet ./ #{tmpdir}/"
      files = Dir.chdir(tmpdir) { Dir.glob("**/*").select { |f| !File.directory?(f) } }
      if_files_changed(node, 'plain', files) do
        rsync_logging = Rake.application.options.silent && '--quiet' || '--verbose'
        sh "#{rsync} #{rsync_logging} ./ root@#{node}:/srv/chef/"
      end
    end

    if_files_changed(node, 'enc', encrypted.keys) do
      encrypted.each do |encrypted_file, target_file|
        sh "gpg --quiet --batch --use-agent --decrypt #{encrypted_file} | ssh root@#{node} 'cat > /srv/chef/#{target_file}; chmod 600 /srv/chef/#{target_file}'"
      end
    end
  end

  desc "converge #{node}"
  task "converge:#{node}" => ["bootstrap:#{node}", "upload:#{node}"] do
    chef_logging = Rake.application.options.silent && '-l fatal' || ''
    sh "ssh root@#{node} 'chef-solo -c /srv/chef/config.rb #{chef_logging} -j /srv/chef/.tmp/#{node}.json'"
  end

  desc "run a command on #{node}"
  task "run:#{node}" => 'run_input' do
    cmd = ['ssh', "root@#{node}", $cmd]
    IO.popen(cmd).lines.each do |line|
      puts "#{node}: #{line}"
    end
  end
end

task :run_input do
  $cmd = ENV['CMD'] || Readline.readline('$ ')
end

desc "upload to all nodes"
task :upload => $nodes.map { |node| "upload:#{node}" }

desc "bootstrap all nodes"
task :bootstrap => $nodes.map { |node| "bootstrap:#{node}" }

desc "converge all nodes (default)"
task "converge" => $nodes.map { |node| "converge:#{node}" }

task "run a command on all nodes"
task :run => $nodes.map { |node| "run:#{node}" }

task :default => :converge
