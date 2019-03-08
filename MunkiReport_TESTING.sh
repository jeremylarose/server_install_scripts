#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version munkireport_version --location '/usr/local/munkireport' --database "mysql or sqlite" --mysqluser username --mysqlpwd password --mysqlhost hostname --mysqlport portnumber
# OR
# ./filename.sh -v version -l location -d "mysql or sqlite" -u mysqlusername -p mysqlpassword -h mysqlhostname -n mysqlhostportnumber

# default variables unless specified from command line
MUNKIREPORT_VERSION="4.0.2"
MUNKIREPORT_LOCATION="/usr/local/munkireport"
DATABASE=sqlite
MYSQL_HOST="127.0.0.1"
MYSQL_HOSTPORT="3306"

PARENTDIR="$(dirname "$MUNKIREPORT_LOCATION")"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# get os version id from system
osversion_id=`cat /etc/*release | grep ^VERSION_ID= | cut -d= -f2 | sed 's/\"//g' | cut -d. -f1`

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            MUNKIREPORT_VERSION="$1"
            ;;
        -l | --location )
            shift
            MUNKIREPORT_LOCATION="$1"
            ;;
        -d | --database )
            shift
            DATABASE="$1"
            ;;
        -u | --mysqluser )
            shift
            MYSQL_USER="$1"
            ;;
        -p | --mysqlpwd )
            shift
            MYSQL_PWD="$1"
            ;;
        -h | --mysqlhost )
            shift
            MYSQL_HOST="$1"
            ;;
        -n | --mysqlport )
            shift
            MYSQL_HOSTPORT="$1"
            ;;
    esac
    shift
done

if [ $DATABASE = mysql ] && [ -z "$MYSQL_USER" ]; then
    echo
    read -p "Enter the Munkireport database username with access: " MYSQL_DBUSER
    echo
fi
if [ $DATABASE = mysql ] && [ -z "$MYSQL_PWD" ]; then
    echo
    while true
    do
        read -s -p "Enter the Munkireport User Database Password: " MYSQL_DBPWD
        echo
        read -s -p "Confirm the Munkireport User Database Password: " password2
        echo
        [ "$ocsdbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi


# install prereqs
if [ $os_family = debian ]; then
  apt -y install wget software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt update
  apt -y install php7.3-mysql php7.3-fpm php7.3-xml
elif [ $os_family = fedora ]; then
  # install prerequisites
  yum -y install epel-release wget
  # add Remi repo for php 7.3
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  # install php 7.3 from repo
  yum --enablerepo=remi-php73 install php php-pdo php-xml
else
  echo "unknown operating system family"
  exit 1
fi

# If fails to exit
if [ $? -ne 0 ]; then
     echo "failed to install all required dependencies"
     exit
fi

# Generate a timestamp
now=$(date +"%Y%m%d_%H%M%S")

# backup current installation if exists
if [ -d ${MUNKIREPORT_LOCATION} ]; then
  cd ${MUNKIREPORT_LOCATION}
  cd ..

  echo "Backing up the munkireport installation to munkireport_backup_$now"
  mv munkireport "munkireport_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# Fetch the new version
echo "Downloading the latest version"
    wget https://github.com/munkireport/munkireport-php/releases/download/v${MUNKIREPORT_VERSION}/munkireport-php-v${MUNKIREPORT_VERSION}.tar.gz
    mkdir -p ${MUNKIREPORT_LOCATION}
    tar -xzf munkireport-php-v${MUNKIREPORT_VERSION}.tar.gz -C ${MUNKIREPORT_LOCATION} --strip-components=1

# put in maintenance mode
touch ${MUNKIREPORT_LOCATION}/storage/framework/down

# set .env file file
if [ $DATABASE = sqlite ]; then
# add MariaDB repo for centos
cat <<-EOF >${MUNKIREPORT_LOCATION}/.env
CONNECTION_DRIVER="sqlite"
CONNECTION_DATABASE="app/db/db.sqlite"
EOF
elif [ $DATABASE = mysql ]; then
cat <<-EOF >${MUNKIREPORT_LOCATION}/.env
CONNECTION_DRIVER="mysql"
CONNECTION_HOST="${MYSQL_HOST}"
CONNECTION_PORT="${MYSQL_HOSTPORT}"
CONNECTION_DATABASE="munkireport"
CONNECTION_USERNAME="${MYSQL_DBUSER}"
CONNECTION_PASSWORD="${MYSQL_DBPWD}"
CONNECTION_CHARSET="utf8mb4"
CONNECTION_COLLATION="utf8mb4_unicode_ci"
CONNECTION_STRICT=TRUE
CONNECTION_ENGINE="InnoDB"
EOF
FI

# Copy across the old configuration files overwiting new
if [ -f ${PARENTDIR}/munkireport_backup_$now/.env ]; then
  mv ${MUNKIREPORT_LOCATION}/.env ${MUNKIREPORT_LOCATION}/.env_example
fi
if [ -d "${PARENTDIR}/munkireport_backup_$now" ]; then
  echo "Copying across previous configuration files"
  cd ${PARENTDIR}/munkireport_backup_$now
  cp -f {config.php,.env,composer.local.json} ${MUNKIREPORT_LOCATION}
fi

# run migrations
cd ${MUNKIREPORT_LOCATION}
php database/migrate.php

# turn off maintenance mode
rm ${MUNKIREPORT_LOCATION}/storage/framework/down
