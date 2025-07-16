#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version gitea_version
# OR
# ./filename.sh -v gitea_version

# install mysql or mariadb seperately (ex: ./MariaDB.sh -r rootpassword -d gitea - u gitea -p dbpassword)

# Version number
GITEA_VERSION="1.24.3"

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
            GITEA_VERSION="$1"
            ;;
    esac
    shift
done

if [ $os_family = debian ]; then
  # create git user to run gitea
  adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
  # allow git user to authenticate pam by adding to shadow group
  usermod -a -G shadow git
  # install prereqs
  apt-get -y install wget make gcc libpam-dev build-essential git
elif [ $os_family = fedora ]; then  
  # create git user to run gitea
  adduser git -s /bin/bash -d /home/git
  mkhomedir_helper git
  # install prereqs
  yum -y install make gcc pam-devel wget git
else
  echo "unknown operating system family"
  exit 1
fi

# If prereqs fail, exit
if [ $? -ne 0 ]; then
    echo "failed to install all required dependencies"
    exit
fi

# stop service if running and download new verison of gitea
systemctl is-active --quiet gitea && systemctl stop gitea
#wget -O /usr/local/bin/gitea https://dl.gitea.io/gitea/${GITEA_VERSION}/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64
wget -O /usr/local/bin/gitea https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64
chmod +x /usr/local/bin/gitea

# create required directory structure
mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
chown git:git /var/lib/gitea/{data,indexers,log}
chmod 750 /var/lib/gitea/{data,indexers,log}
mkdir -p /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# create systemd service and start gitea
if [[ -e /etc/systemd/system/ ]]; then
cat <<-EOF >/etc/systemd/system/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
Requires=mysql.service

[Service]
LimitMEMLOCK=infinity
LimitNOFILE=65535
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
fi

# enable and start gitea service
systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

echo -e "Installation complete, point your browser to http://server:3000
|        to configure your new Gitea installation."
# temporarily open firewall for fedora
if [ $os_family = fedora ]; then
  echo "be sure to open firewall ports, example:"
  # temporarily open firewall (don't forget to restrict)
  echo "firewall-cmd --permanent --add-port=3000/tcp"
  echo "firewall-cmd --reload"
fi
