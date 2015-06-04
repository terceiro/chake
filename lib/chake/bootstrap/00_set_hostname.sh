hostname="$1"

echo "$hostname" > /etc/hostname
hostname --file /etc/hostname

# Stop cloud-init from resetting the hostname
if [ -f /etc/cloud/cloud.cfg ]; then
  sed -i -e '/^\s*-\s*\(set_hostname\|update_hostname\)/d' /etc/cloud/cloud.cfg
fi
