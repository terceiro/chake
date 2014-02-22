file '/tmp/chake.test' do
  content   "It works on #{node[:fqdn]}!\n"
  mode      '0644'
  owner     'root'
  group     'root'
end

cookbook_file '/tmp/chake.test.unencrypted' do
  source    'test'
  mode      '0600'
  owner     'root'
  group     'root'
end
