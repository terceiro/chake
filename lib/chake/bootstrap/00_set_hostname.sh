hostname="$1"

echo "$hostname" > /etc/hostname
hostname --file /etc/hostname
