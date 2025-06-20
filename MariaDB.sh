#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --rootpwd password --dbname databasename --dbuser username --dbpwd password --mariadb_version version
# OR
# ./filename.sh -r password -d databasename -u username -p password -v version

# set default variables
mariadb_version='11.8'

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
  os_codename='unknown'
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -r | --rootpwd )
            shift
            rootpwd="$1"
            ;;
        -d | --dbname )
            shift
            dbname="$1"
            ;;
        -u | --dbuser )
            shift
            dbuser="$1"
            ;;            
        -p | --dbpwd )
            shift
            dbpwd="$1"
            ;;            
        -v | --mariadb_version )
            shift
            mariadb_version="$1"
            ;;
esac
    shift
done

# Get database information from terminal if not provided as arguments:
if [ -z "$rootpwd" ]; then
    echo 
    while true
    do
        read -s -p "Enter a MariaDB ROOT Password: " rootpwd
        echo
        read -s -p "Confirm MariaDB ROOT Password: " password2
        echo
        [ "$rootpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
fi
if [ -z "$dbname" ]; then
    echo
    read -p "Enter a Database to create: " dbname
    echo
fi
if [ -z "$dbuser" ]; then
    echo
    read -p "Enter a username to give permissions to $dbname: " dbuser
    echo
fi
if [ -z "$dbpwd" ]; then
    echo
    while true
    do
        read -s -p "Enter a password for $dbuser: " dbpwd
        echo
        read -s -p "Confirm pasword for $dbuser: " password2
        echo
        [ "$dbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# install only if mysql not already installed AND os family matches
/usr/bin/mariadb --version
RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo
  echo mysql already installed
  echo
elif [ $RESULT -ne 0 ] && [ $os_family = debian ]; then
  # install MariaDB bypassing password prompt
  debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $rootpwd"
  debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $rootpwd"
  
  # install MariaDB
  apt -y install ca-certificates apt-transport-https
  curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="mariadb-$mariadb_version"
  apt update
  apt -y install mariadb-server mariadb-client
  
  if [ $? -eq 0 ]; then
    echo "MariaDB $mariadb_version installed successfully"
  fi

elif [ $RESULT -ne 0 ] && [ $os_family = fedora ] && [ $osversion_id = 8 ]; then

yum -y install mariadb-server
yum -y install mariadb

elif [ $RESULT -ne 0 ] && [ $os_family = fedora ]; then
# add MariaDB repo for centos
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="mariadb-$mariadb_version"

# Insall MariaDB
yum -y install MariaDB-server
yum -y install MariaDB-client

if [ $? -eq 0 ]; then
  echo "MariaDB $mariadb_version installed successfully"
fi
else
echo
echo "unsupported OS Family to install MariaDB"
echo
exit 1
fi

if [ $RESULT -ne 0 ] && [ $os_family = fedora ]; then
# enable and start service
systemctl enable mariadb
systemctl start mariadb

# secure MariaDB and set root
mysql_secure_installation<<EOF

y
$rootpwd
$rootpwd
y
y
y
y
EOF
fi

# create database
/usr/bin/mariadb -uroot -p$rootpwd <<MYSQL_SCRIPT
CREATE DATABASE $dbname;
MYSQL_SCRIPT
if [ $? -eq 0 ]; then
  echo "database $dbname created"
fi

# create db user and grant privileges
/usr/bin/mariadb -uroot -p$rootpwd <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@localhost IDENTIFIED BY '$dbpwd';
MYSQL_SCRIPT
if [ $? -eq 0 ]; then
  echo "$dbuser granted privileges on $dbname"
fi
