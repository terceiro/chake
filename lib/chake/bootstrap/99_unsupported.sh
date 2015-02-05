echo "---------------------"
echo "Unsupported platform:"
echo "---------------------"
echo
for file in /etc/os-release /etc/issue; do
  if [ -f $file ]; then
    cat $file
    break
  fi
done
exit 1
