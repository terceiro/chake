echo "---------------------"
echo "Unsupported platform: Installing itamae with rubygems"
echo "---------------------"
echo

for file in /etc/os-release /etc/issue; do
  if [ -f $file ]; then
    cat $file
    break
  fi
done

if ! which itamae >/dev/null ; then
  gem install itamae
  exit
fi
