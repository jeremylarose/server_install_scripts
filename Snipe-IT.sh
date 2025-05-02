#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version snipeit_version --location '/var/www/snipe-it' --mysqluser username --mysqlpwd password --mysqlhost hostname --mysqlport portnumber
# OR
# ./filename.sh -v version -l location -u mysqlusername -p mysqlpassword -h mysqlhostname -n mysqlhostportnumber

# default variables unless specified from command line
SNIPEIT_VERSION="8.1.1"
SNIPEIT_LOCATION="/var/www/snipe-it"
MYSQL_HOST="127.0.0.1"
MYSQL_HOSTPORT="3306"

PARENTDIR="$(dirname "$SNIPEIT_LOCATION")"

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
            SNIPEIT_VERSION="$1"
            ;;
        -l | --location )
            shift
            SNIPEIT_LOCATION="$1"
            ;;
        -u | --mysqluser )
            shift
            MYSQL_DBUSER="$1"
            ;;
        -p | --mysqlpwd )
            shift
            MYSQL_DBPWD="$1"
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

if [ -z "$MYSQL_DBUSER" ]; then
    echo
    read -p "Enter the Snipe-IT database username with access: " MYSQL_DBUSER
    echo
fi
if [ -z "$MYSQL_DBPWD" ]; then
    echo
    while true
    do
        read -s -p "Enter the Snipe-IT User Database Password: " MYSQL_DBPWD
        echo
        read -s -p "Confirm the Snipe-IT User Database Password: " password2
        echo
        [ "$MYSQL_DBPWD" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi


# install prereqs
if [ $os_family = debian ]; then
  apt -y install wget software-properties-common unzip
  add-apt-repository -y ppa:ondrej/php
  apt update
  apt -y install php8.3-fpm php8.3-xml php8.3-mysql
elif [ $os_family = fedora ] && [ $osversion_id = 8 ]; then
  yum -y install epel-release wget unzip
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  dnf module install -y php:remi-8.3
  dnf install -y php-mysqlnd
elif [ $os_family = fedora ]; then
  # install prerequisites
  yum -y install epel-release wget tar
  # add Remi repo for php 8.3 for 
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  # install php 8.3 from repo
  yum --enablerepo=remi-php83 -y install php php-pdo php-xml php-mysql
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
if [ -d ${SNIPEIT_LOCATION} ]; then
  cd ${SNIPEIT_LOCATION}
  cd ..

  echo "Backing up the snipeit installation to snipeit_backup_$now"
  mv snipe-it "snipeit_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# Fetch the new version
echo "Downloading the latest version"
    wget -O snipe-it-${SNIPEIT_VERSION}.zip https://github.com/grokability/snipe-it/archive/refs/tags/v${SNIPEIT_VERSION}.zip
    unzip snipe-it-${SNIPEIT_VERSION}.zip
    rm snipe-it-${SNIPEIT_VERSION}.zip
    mkdir -p ${PARENTDIR}
    mv snipe-it-${SNIPEIT_VERSION} ${PARENTDIR}
    mv ${PARENTDIR}/snipe-it-${SNIPEIT_VERSION} ${SNIPEIT_LOCATION}

# set .env file file
cat <<-EOF >${SNIPEIT_LOCATION}/.env
	DB_CONNECTION="mysql"
	DB_DATABASE="snipe-it"
	DB_HOST="${MYSQL_HOST}"
	DB_PORT="${MYSQL_HOSTPORT}"
	DB_USERNAME="${MYSQL_DBUSER}"
	DB_PASSWORD="${MYSQL_DBPWD}"
	EOF
fi

# Copy across the old configuration files overwiting new
if [ -f ${PARENTDIR}/snipeit_backup_$now/.env ]; then
  mv ${SNIPEIT_LOCATION}/.env ${SNIPEIT_LOCATION}/.env_backup
fi
if [ -d "${PARENTDIR}/snipeit_backup_$now" ]; then
  echo "Copying across previous configuration files"
  cd ${PARENTDIR}/snipeit_backup_$now
  cp -f {config.php,.env,composer.local.json} ${SNIPEIT_LOCATION}
fi


