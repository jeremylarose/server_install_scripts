#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version wordpress_version --location '/var/www/html/wordpress'
# OR
# ./filename.sh -v version -l location

# default variables unless specified from command line
WORDPRESS_VERSION="6.8.1"
WORDPRESS_LOCATION="/var/www/html"

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
            WORDPRESS_VERSION="$1"
            ;;
        -l | --location )
            shift
            WORDPRESS_LOCATION="$1"
            ;;
    esac
    shift
done

# install prereqs
if [ $os_family = debian ]; then
  apt -y install wget software-properties-common unzip less
  add-apt-repository -y ppa:ondrej/php
  apt update
  apt -y install php8.4 php8.4-cli php8.4-common php8.4-imap php8.4-fpm php8.4-snmp php8.4-xml php8.4-zip php8.4-mbstring php8.4-curl php8.4-mysql php8.4-gd php8.4-intl
elif [ $os_family = fedora ] && [ $osversion_id = 8 ]; then
  yum -y install epel-release wget unzip
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  dnf module install -y php:remi-8.4
  dnf install -y php-mysqlnd
elif [ $os_family = fedora ]; then
  # install prerequisites
  yum -y install epel-release wget tar
  # add Remi repo for php 8.4 for 
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  # install php 8.4 from repo
  yum --enablerepo=remi-php84 -y install php php-pdo php-xml
  yum --enablerepo=remi-php84 -y install php-mysql
else
  echo "unknown operating system family77"
  exit 1
fi

# install wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# If fails to exit
if [ $? -ne 0 ]; then
     echo "failed to install all required dependencies"
     exit
fi

PARENTDIR="$(dirname "$WORDPRESS_LOCATION")"

# Generate a timestampmdlm
now=$(date +"%Y%m%d_%H%M%S")

# backup current installation if exists
if [ -d ${WORDPRESS_LOCATION} ]; then
  cd ${WORDPRESS_LOCATION}
  cd ..

  echo "Backing up the wordpress installation to wordpress_backup_$now"
  mv ${WORDPRESS_LOCATION} "wordpress_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# Fetch the new version
echo "Downloading the latest version"
    wget https://wordpress.org/wordpress-${WORDPRESS_VERSION}.zip
    unzip wordpress-${WORDPRESS_VERSION}.zip
    rm wordpress-${WORDPRESS_VERSION}.zip
    mkdir -p ${PARENTDIR}
    mv wordpress ${WORDPRESS_LOCATION}

# Copy across the old configuration files overwiting new
if [ -d "${PARENTDIR}/wordpress_backup_$now" ]; then
  echo "Copying across previous configuration file"
  cd ${PARENTDIR}/wordpress_backup_$now
  cp -f {wp-config.php,.htaccess,} ${WORDPRESS_LOCATION}
  rsync -aP ${PARENTDIR}/wordpress_backup_$now/wp-content/themes/ ${WORDPRESS_LOCATION}/wp-content/themes -delete
  rsync -aP ${PARENTDIR}/wordpress_backup_$now/wp-content/plugins/ .${WORDPRESS_LOCATION}/wp-content/plugins -delete
  rsync -aP ${PARENTDIR}/wordpress_backup_$now/wp-content/languages/ ${WORDPRESS_LOCATION}/wp-content/languages -delete
  rsync -aP ${PARENTDIR}/wordpress_backup_$now/wp-content/mu-plugins/ ${WORDPRESS_LOCATION}/wp-content/mu-plugins -delete
  rsync -aP ${PARENTDIR}/wordpress_backup_$now/wp-content/uploads/ ${WORDPRESS_LOCATION}/wp-content/uploads -delete
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
