#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version mc_version
# OR
# ./filename.sh -v mc_version

# default variables unless specified from command line
MC_VERSION="0.4.8-p"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            MC_VERSION="$1"
            ;;
    esac
    shift
done

# install prereqs
if [ $os_family = debian ]; then
  apt-get -y install wget nodejs npm
  # install mongodb
  apt-get -y install mongodb
  systemctl start mongodb
  systemctl enable mongodb
elif [ $os_family = fedora ]; then
  echo "os not supported yet"
  exit
else
  echo "unknown operating system family"
  exit 1
fi

# allow to nodejs to listen to ports below 1024
  setcap cap_net_bind_service=+ep /usr/bin/node

# create service account, directories and install meshcentral
  useradd -r -s /sbin/nologin meshcentral
  mkdir -p /opt/meshcentral
  cd /opt/meshcentral
  npm install meshcentral
  mkdir -p /opt/meshcentral/meshcentral-files
  mkdir -p /opt/meshcentral/meshcentral-data
  chown -R meshcentral:meshcentral /opt/meshcentral
  chmod -R 755 /opt/meshcentral/meshcentral-files

# enable mongodb
  sed -i "s/_MongoDB/MongoDB/" /opt/meshcentral/meshcentral-data/config.json
  sed -i "s/_MongoDbName/MongoDbName/" /opt/meshcentral/meshcentral-data/config.json
  
# create systemd service and start meshcentral
if [[ -e /etc/systemd/system/ ]]; then
cat <<-EOF >/etc/systemd/system/meshcentral.service
[Unit]
Description=MeshCentral Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/usr/bin/node /opt/meshcentral/node_modules/meshcentral
WorkingDirectory=/opt/meshcentral
Environment=NODE_ENV=production
User=meshcentral
Group=meshcentral
Restart=always
# Restart service after 10 seconds if node service crashes
RestartSec=10
# Set port permissions capability
AmbientCapabilities=cap_net_bind_service
[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable meshcentral.service
systemctl enable meshcentral.service

service meshcentral start
