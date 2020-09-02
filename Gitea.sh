#!/bin/bash

# install mysql or mariadb seperately (ex: ./MariaDB.sh -r rootpassword -d gitea - u gitea -p dbpassword)

# Version numbers
GOVERSION="1.15.1"
GITEA_VERSION="1.12.3"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

if [ $os_family = debian ]; then
  # create git user to run gitea
  adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
  # allow git user to authenticate pam by adding to shadow group
  usermod -a -G shadow git
  # install prereqs
  apt-get -y install make gcc libpam-dev build-essential git
  # install nodejs 10
  apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
  curl -sL https://deb.nodesource.com/setup_10.x | sudo bash
  apt update
  apt -y install gcc g++ make
  apt -y install nodejs
elif [ $os_family = fedora ]; then  
  # create git user to run gitea
  adduser git -s /bin/bash -d /home/git
  mkhomedir_helper git
  # install prereqs
  yum -y install make gcc pam-devel wget git
  # install nodejs 10
  curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
  yum -y install nodejs
else
  echo "unknown operating system family"
  exit 1
fi

# If prereqs fail, exit
if [ $? -ne 0 ]; then
    echo "failed to install all required dependencies"
    exit
fi

# Download GO to build gitea
wget https://dl.google.com/go/go${GOVERSION}.linux-amd64.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download go${GOVERSION}.linux-amd64.tar.gz"
    echo "https://dl.google.com/go/go${GOVERSION}.linux-amd64.tar.gz"
    exit
fi

# Extract GO
tar -xzf go${GOVERSION}.linux-amd64.tar.gz

# set temporary environment variables
CWD=$(pwd)
export GOROOT=$CWD/go
export GOPATH=$CWD/go/working
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# create gitea binary with pam using go
go get -d -u code.gitea.io/gitea
cd $GOPATH/src/code.gitea.io/gitea
git reset -- hard
git pull
git checkout v${GITEA_VERSION}

TAGS="bindata" make generate build

cp -f $GOPATH/src/code.gitea.io/gitea/gitea /usr/local/bin

# create required directory structure
mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
chown git:git /var/lib/gitea/{data,indexers,log}
chmod 750 /var/lib/gitea/{data,indexers,log}
mkdir -p /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# copy gitea systemd service
cp $GOPATH/src/code.gitea.io/gitea/contrib/systemd/gitea.service /etc/systemd/system/gitea.service

# remove go files
rm -rf $GOROOT

# uncomment mysqld.service in gitea systemd service
sed -i '/mysqld.service/s/^#//g' /etc/systemd/system/gitea.service

# enable and start gitea service
systemctl enable gitea
systemctl start gitea
systemctl restart gitea

echo -e "Installation complete, point your browser to http://server:3000
|        to configure your new Gitea installation."
# temporarily open firewall for fedora
if [ $os_family = fedora ]; then
  echo "be sure to open firewall ports, example:"
  # temporarily open firewall (don't forget to restrict)
  echo "firewall-cmd --permanent --add-port=3000/tcp"
  echo "firewall-cmd --reload"
fi
