#!/bin/bash

# install mysql or mariadb seperately (ex: ./MariaDB_CentOS.sh -r rootpassword -n gitea - u gitea -p dbpassword)

# Version numbers
GOVERSION="1.10.3"
GITEA_VERSION="1.5.0"

# Install prereqs
yum -y install make gcc pam-devel wget git

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
git checkout v${GITEA_VERSION}

TAGS="pam bindata" make generate build

cp -f $GOPATH/src/code.gitea.io/gitea/gitea /usr/local/bin

# create git user to run gitea
adduser git -s /sbin/nologin

# allow git user to authenticate pam by adding to shadow group
# usermod -a -G shadow git

# create required directory structure
mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
chown git:git /var/lib/gitea/{data,indexers,log}
chmod 750 /var/lib/gitea/{data,indexers,log}
mkdir -p /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# copy gitea systemd service
cp $GOPATH/src/code.gitea.io/gitea/contrib/systemd/gitea.service /etc/systemd/system/gitea.service

# uncomment mysqld.service in gitea systemd service
sed -i '/mysqld.service/s/^#//g' /etc/systemd/system/gitea.service

# enable and start gitea service
systemctl enable gitea
systemctl start gitea

# temporarily open firewall (don't forget to restrict)
firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --reload

echo -e "Installation complete, point your browser to http://server:3000
|        to configure your new Gitea installation."
