if [ -x /usr/bin/apt-get ]; then
  apt-get update
  export DEBIAN_FRONTEND=noninteractive
  apt-get -q -y install rsync itamae
  exit
fi
