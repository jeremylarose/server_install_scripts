#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version xibo_version --composeversion docker-compose_version --dbname databasename --dbuser username --dbpwd password --dbhost hostname --dbhostportnumber portnumber
# OR
# ./filename.sh -v version -cv compose-version -d databasename -u username -p password -h hostname -n hostportnumber

# install mysql or mariadb seperately (ex: ./MariaDB.sh -r rootpassword -d cms -u cms -p dbpassword)

# default variables unless specified from command line
XIBO_VERSION="2.3.6"
DOCKERCOMPOSE_VERSION="1.26.2"
xibodbhost="localhost"
xibodbhostport="3306"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -d | --dbname )
            shift
            xibodbname="$1"
            ;;
        -u | --dbuser )
            shift
            xibodbuser="$1"
            ;;
        -p | --dbpwd )
            shift
            xibodbpwd="$1"
            ;;
        -h | --dbhost )
            shift
            xibodbhost="$1"
            ;;
        -n | --dbhostportnumber )
            shift
            xibodbhostport="$1"
            ;;
        -v | --version )
            shift
            XIBO_VERSION="$1"
            ;;
        -cv | --composeversion )
            shift
            DOCKERCOMPOSE_VERSION="$1"
            ;;
    esac
    shift
done

if [ -z "$xibodbname" ]; then
    echo
    read -p "Enter the Xibo Database name: " xibodbname
    echo
fi
if [ -z "$xibodbuser" ]; then
    echo
    read -p "Enter a username with permissions to $xibodbname: " xibodbuser
    echo
fi
if [ -z "$xibodbpwd" ]; then
    echo
    while true
    do
        read -s -p "Enter the Xibo CMS User Database Password for cms: " xibodbpwd
        echo
        read -s -p "Confirm the Xibo CMS User Database Password for cms: " password2
        echo
        [ "$xibodbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# install Docker Compose (Docker should already be installed)
curl -L https://github.com/docker/compose/releases/download/${DOCKERCOMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    echo "Failed to download docker-compose ${DOCKERCOMPOSE_VERSION}"
fi


# backup current version if installed
now=$(date +"%Y%m%d_%H%M%S")
if [ -d "/opt/xibo" ]; then
  cd /opt/xibo
  docker-compose stop
  cd ..

  echo "Backing up the Xibo installation to xibo_backup_$now"
  mv xibo "xibo_backup_$now"
  mkdir /opt/xibo
  cp xibo_backup_$now/config.env /opt/xibo
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi
# install or upgrade Xibo CMS
mkdir /opt/xibo
cd /opt/xibo
wget https://github.com/xibosignage/xibo-cms/releases/download/${XIBO_VERSION}/xibo-docker.tar.gz
tar --strip-components=1 -zxvf xibo-docker.tar.gz
rm xibo-docker.tar.gz

if [ $? -ne 0 ]; then
    echo "Failed to download Xibo CMS ${XIBO_VERSION}"
fi

# copy config file if not exist and set mysql password
if [[ ! -f /opt/xibo/config.env ]]; then
cat <<EOF >/opt/xibo/config.env
MYSQL_HOST=$xibodbhost
MYSQL_PORT=$xibodbhostport
MYSQL_DATABASE=$xibodbname
MYSQL_USER=$xibodbuser
MYSQL_PASSWORD=$xibodbpwd
EOF
fi

# Bring CMS up with Docker Compose
cd /opt/xibo
docker-compose up -d

echo "Xibo CMS $XIBO_VERSION setup/upgrade complete https://xibo.org.uk/docs/setup/cms-installation-guides"
