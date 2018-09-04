#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --mysqlpwd password --ocspwd password
# OR
# ./filename.sh -m password -o password

# Version number of OCS Inventory and MariaDB to install
OCSVERSION="2.5"
MARIADB_VERSION='10.3'

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -m | --mysqlpwd )
            shift
            mysqlpwd="$1"
            ;;
        -o | --ocspwd )
            shift
            ocspwd="$1"
            ;;
    esac
    shift
done

# Get MariaDB root password and Ocs Inventory Database User password
if [ -n "$mysqlpwd" ] && [ -n "$ocspwd" ]; then
        mysqlrootpassword=$mysqlpwd
        ocsdbuserpassword=$ocspwd
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
        read -s -p "Enter an OCS Inventory User Database Password: " ocsdbuserpassword
        echo
        read -s -p "Confirm OCS Inventory User Database Password: " password2
        echo
        [ "$ocsdbuserpassword" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# install MariaDB bypassing password prompt
debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $mysqlrootpassword"
debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $mysqlrootpassword"

# install MariaDB
# -qq implies -y --force-yes
apt-get -y install software-properties-common
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository "deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/$MARIADB_VERSION/ubuntu bionic main"
apt-get update
apt-get install -qq mariadb-server mariadb-client

# create database
mysql -uroot -p$mysqlrootpassword <<MYSQL_SCRIPT
CREATE DATABASE ocsweb;
MYSQL_SCRIPT

# create ocs db user and grant privileges
mysql -uroot -p$mysqlrootpassword <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON ocsweb.* TO ocs_dbuser@localhost IDENTIFIED BY '$ocsdbuserpassword';
MYSQL_SCRIPT

# Install more prereqs
apt-get -y install php-curl apache2-dev gcc perl-modules-5.26 make apache2 php perl libapache2-mod-perl2 libapache2-mod-php \
libio-compress-perl libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libsoap-lite-perl libnet-ip-perl php-mysql \
php-gd php7.2-dev php-mbstring php-soap php-xml php-pclzip libarchive-zip-perl php7.2-zip cpanminus

cpanm Apache2::SOAP

cpanm XML::Entities

cpanm Net::IP

cpanm Apache::DBI

cpanm Mojolicious::Lite

cpanm Switch

cpanm Plack::Handler

# If apt fails to run completely the rest of this isn't going to work...
if [ $? -ne 0 ]; then
    echo "apt-get failed to install all required dependencies"
    exit
fi

# Download OCS Inventory Server
wget -O OCSNG_UNIX_SERVER_${OCSVERSION}.tar.gz https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCSVERSION}/OCSNG_UNIX_SERVER_${OCSVERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download OCSNG_UNIX_SERVER_${OCSVERSION}.tar.gz"
    echo "https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCSVERSION}/OCSNG_UNIX_SERVER_${OCSVERSION}.tar.gz"
    exit
fi

# Extract OCS Inventory files
tar -xzf OCSNG_UNIX_SERVER_${OCSVERSION}.tar.gz

# modify setup.sh with new database user
DB_SERVER_USER_REPLACETEXT="DB_SERVER_USER="
DB_SERVER_USER_NEW='DB_SERVER_USER="ocs_dbuser"'
sed -i "/$DB_SERVER_USER_REPLACETEXT/c $DB_SERVER_USER_NEW" OCSNG_UNIX_SERVER_${OCSVERSION}/setup.sh

# modify setup.sh with new database user password
DB_SERVER_PWD_REPLACETEXT="DB_SERVER_PWD="
DB_SERVER_PWD_NEW=DB_SERVER_USER="$ocsdbuserpassword"
sed -i "/$DB_SERVER_PWD_REPLACETEXT/c $DB_SERVER_PWD_NEW" OCSNG_UNIX_SERVER_${OCSVERSION}/setup.sh

# run unattended setup script
cd OCSNG_UNIX_SERVER_${OCSVERSION}
yes "" | sh setup.sh


# enable Apache configuration with aliases
if [ ! -e "/etc/apache2/conf-enabled/ocsinventory-reports.conf" ]
then
	ln -s /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
	:
fi
if [ ! -e "/etc/apache2/conf-enabled/z-ocsinventory-server.conf" ]
then
	ln -s /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-enabled/z-ocsinventory-server.conf
	:
fi
if [ ! -e "/etc/apache2/conf-enabled/zz-ocsinventory-restapi.conf" ]
then
	ln -s /etc/apache2/conf-available/zz-ocsinventory-restapi.conf /etc/apache2/conf-enabled/zz-ocsinventory-restapi.conf
	:
fi

# modify z-ocsinventory-server.conf with new database user and password replacing lines
OCS_DB_USER_REPLACETEXT='PerlSetEnv OCS_DB_USER'
OCS_DB_USER_NEW='\  PerlSetEnv OCS_DB_USER ocs_dbuser'
sed -i "/$OCS_DB_USER_REPLACETEXT/c $OCS_DB_USER_NEW" /etc/apache2/conf-available/z-ocsinventory-server.conf

OCS_DB_PWD_REPLACETEXT='PerlSetVar OCS_DB_PWD'
OCS_DB_PWD_NEW="\  PerlSetVar OCS_DB_PWD $ocsdbuserpassword"
sed -i "/$OCS_DB_PWD_REPLACETEXT/c $OCS_DB_PWD_NEW" /etc/apache2/conf-available/z-ocsinventory-server.conf

# modify zz-ocsinventory-restapi.conf with new database user password
OCS_DB_USER_RESTAPI_REPLACETEXT='{OCS_DB_USER} ='
OCS_DB_USER_RESTAPI_NEW="\  \$ENV{OCS_DB_USER} = 'ocs_dbuser';"
sed -i "/$OCS_DB_USER_RESTAPI_REPLACETEXT/c $OCS_DB_USER_RESTAPI_NEW" /etc/apache2/conf-available/zz-ocsinventory-restapi.conf

OCS_DB_PWD_RESTAPI_REPLACETEXT='{OCS_DB_PWD} ='
OCS_DB_PWD_RESTAPI_NEW="\  \$ENV{OCS_DB_PWD} = 'zzreplaceholder';"
sed -i "/$OCS_DB_PWD_RESTAPI_REPLACETEXT/c $OCS_DB_PWD_RESTAPI_NEW" /etc/apache2/conf-available/zz-ocsinventory-restapi.conf
sed -i "s/zzreplaceholder/$ocsdbuserpassword/" /etc/apache2/conf-available/zz-ocsinventory-restapi.conf


# ensure proper permissions and restart Apache
chown -R www-data:www-data /var/lib/ocsinventory-reports
systemctl restart apache2


echo -e "Installation complete, point your browser to http://server//ocsreports
|        to configure database server and create/update schema."
