#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --mysqlpwd password --giteadbpwd password
# OR
# ./filename.sh -m password -g password


# Version numbers
GOVERSION="1.10.3"
MARIADB_VERSION='10.3'
GITEA_VERSION="1.5.0"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -m | --mysqlpwd )
            shift
            mysqlpwd="$1"
            ;;
        -g | --giteadbpwd )
            shift
            giteadbpwd="$1"
            ;;
    esac
    shift
done

# Get MariaDB root password and Gitea Database User password
if [ -n "$mysqlpwd" ] && [ -n "$giteadbpwd" ]; then
        mysqlrootpassword=$mysqlpwd
        giteapassword=$giteadbpwd
else
    echo 
    while true
    do
        read -s -p "Enter a MariaDB ROOT Password: " mysqlrootpassword
        echo
        read -s -p "Confirm MariaDB ROOT Password: " password2
        echo
        [ "$mysqlrootpassword" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
    while true
    do
        read -s -p "Enter a Gitea User Database Password: " giteapassword
        echo
        read -s -p "Confirm Gitea User Database Password: " password2
        echo
        [ "$giteapassword" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# add MariaDB repo for centos
cat <<EOF >/etc/yum.repos.d/mariadb.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/$MARIADB_VERSION/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# Insall MariaDB

yum -y install MariaDB-server MariaDB-client

# enable and start service
systemctl enable mariadb
systemctl start mariadb

# secure MariaDB and set root
mysql_secure_installation<<EOF

y
$mysqlrootpassword
$mysqlrootpassword
y
y
y
y
EOF

# create database
mysql -uroot -p$mysqlrootpassword <<MYSQL_SCRIPT
CREATE DATABASE gitea;
MYSQL_SCRIPT

# create db user and grant privileges
mysql -uroot -p$mysqlrootpassword <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON gitea.* TO gitea@localhost IDENTIFIED BY '$giteapassword';
MYSQL_SCRIPT

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

echo -e "Installation complete, point your browser to http://server:3000
|        to configure your new Gitea installation."


firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --reload
