echo "---------------------"
echo "Unsupported platform: Installing chef-solo with omnibus package"
echo "---------------------"
echo

for file in /etc/os-release /etc/issue; do
  if [ -f $file ]; then
    cat $file
    break
  fi
done

if ! which chef-solo >/dev/null ; then
  # Install chef-solo via omnibus package that chef provides
  # This script should install chef-solo in any Linux distribution
  wget -O- https://opscode.com/chef/install.sh | bash
  exit
fi
