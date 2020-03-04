#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version mc_version
# OR
# ./filename.sh -v mc_version

# default variables unless specified from command line
MC_VERSION="0.4.9-u"
MONGODB_VERSION="4.2"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os version id from system
osversion_id=`cat /etc/*release | grep ^VERSION_ID= | cut -d= -f2 | sed 's/\"//g' | cut -d. -f1`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# get os_codename from system
if [ $os = debian ] || [ $os = centos ] || [ $os = rhel ]; then
  os_codename=`cat /etc/*release | grep ^VERSION= | cut -d'(' -f2 | cut -d')' -f1 | awk '{print tolower($0)}'`
elif [ $os = ubuntu ]; then
  os_codename=`cat /etc/*release | grep ^DISTRIB_CODENAME= | cut -d= -f2`
else
  echo "unknown os codename"
  exit 1
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
  # install nodejs 10 and npm
  apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
  curl -sL https://deb.nodesource.com/setup_10.x | sudo bash
  apt update
  apt -y install gcc g++ make
  apt -y install nodejs npm
  
  # install mongodb
  apt -y install gnupg
  wget -qO - https://www.mongodb.org/static/pgp/server-$MONGODB_VERSION.asc | sudo apt-key add -
  if [ $os = debian ]; then
  echo "deb http://repo.mongodb.org/apt/$os $os_codename/mongodb-org/$MONGODB_VERSION main" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list
  elif [ $os = ubuntu ]; then
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/$os $os_codename/mongodb-org/$MONGODB_VERSION multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list
  fi
  apt update
  apt -y install mongodb-org
  systemctl daemon-reload
  systemctl enable mongod
  systemctl start mongod
  
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
  useradd -r -m -s /sbin/nologin meshcentral
  mkdir -p /opt/meshcentral
  cd /opt/meshcentral
  chown -R meshcentral:meshcentral /opt/meshcentral
  sudo -H -u meshcentral bash -c 'cd /opt/meshcentral && npm install meshcentral'
  mkdir -p /opt/meshcentral/meshcentral-files
  mkdir -p /opt/meshcentral/meshcentral-data
  chown -R meshcentral:meshcentral /opt/meshcentral
  chmod -R 755 /opt/meshcentral/meshcentral-files

# copy config file if not exist already and enable mongodb
  if [[ ! -f /opt/meshcentral/meshcentral-data/config.json ]]; then
  cp /opt/meshcentral/node_modules/meshcentral/sample-config.json /opt/meshcentral/meshcentral-data/config.json
  sed -i "s/_MongoDb/MongoDb/" /opt/meshcentral/meshcentral-data/config.json
  sed -i "s/_MongoDbName/MongoDbName/" /opt/meshcentral/meshcentral-data/config.json
  sed -i "s/MongoDbChangeStream/_MongoDbChangeStream/" /opt/meshcentral/meshcentral-data/config.json
  fi

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

echo -e "Installation complete, wait a bit for service to start the first time and to got https://localhost to access site"
