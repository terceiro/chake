hostname="$1"

echo "$hostname" > /etc/hostname
hostname --file /etc/hostname

fqdn=$(hostname --fqdn || true)
if [ "$fqdn" != "$hostname" ]; then
  printf "127.0.1.1\t%s\n" "$hostname" >> /etc/hosts
fi

# Stop cloud-init from resetting the hostname
if [ -f /etc/cloud/cloud.cfg ]; then
  sed -i -e '/^\s*-\s*\(set_hostname\|update_hostname\)/d' /etc/cloud/cloud.cfg
fi
