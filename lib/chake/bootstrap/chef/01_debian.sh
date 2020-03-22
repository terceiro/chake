if [ -x /usr/bin/apt-get ]; then
  apt-get update
  export DEBIAN_FRONTEND=noninteractive
  apt-get -q -y install rsync chef
  update-rc.d chef-client disable
  service chef-client stop
  exit
fi
