#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --rootpwd password --dbname databasename --dbuser username --dbpwd password --mariadb_version version
# OR
# ./filename.sh -r password -d databasename -u username -p password -v version

# defaults
mariadb_version='10.3'
os="cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }' | awk '{print tolower($0)}'"
os_codename="cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'"

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

# install only if mysql not already installed
mysql --version
RESULT=$?

if [ $RESULT -ne 0 ]; then
  # install MariaDB bypassing password prompt
  debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $rootpwd"
  debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $rootpwd"
  
  # install MariaDB
  # -qq implies -y --force-yes
  apt-get -y install software-properties-common
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
  add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/$mariadb_version/$os $os_codename main"
  apt-get update
  apt-get install -qq mariadb-server mariadb-client
else
  echo
  echo mysql arleady installed
  echo
  mysql --version
  echo
fi

# create database
mysql -uroot -p$rootpwd <<MYSQL_SCRIPT
CREATE DATABASE $dbname;
MYSQL_SCRIPT

# create db user and grant privileges
mysql -uroot -p$rootpwd <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@localhost IDENTIFIED BY '$dbpwd';
MYSQL_SCRIPT
