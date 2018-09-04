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
CREATE DATABASE ocsweb;
MYSQL_SCRIPT

# create db user and grant privileges
mysql -uroot -p$mysqlrootpassword <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON ocsweb.* TO ocs_dbuser@localhost IDENTIFIED BY '$ocsdbuserpassword';
MYSQL_SCRIPT

# install epel repo
yum --enablerepo=extras -y install epel-release

# Install more prereqs
yum install -y php-curl httpd httpd-devel gcc mod_perl mod_php mod_ssl make perl-XML-Simple perl-Compress-Zlib perl-DBI \
perl-DBD-MySQL perl-Net-IP perl-SOAP-Lite perl-Archive-Zip php-common php-gd php-mbstring php-soap php-mysql php-ldap \
php-xml cpanminus

cpanm XML::Entities

cpanm Net::IP

cpanm Apache::DBI

cpanm Mojolicious::Lite

cpanm Switch

cpanm Plack::Handler

# enable and start httpd
systemctl enable httpd
systemctl start httpd

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

# modify z-ocsinventory-server.conf with new database user and password replacing lines
OCS_DB_USER_REPLACETEXT='PerlSetEnv OCS_DB_USER'
OCS_DB_USER_NEW='\  PerlSetEnv OCS_DB_USER ocs_dbuser'
sed -i "/$OCS_DB_USER_REPLACETEXT/c $OCS_DB_USER_NEW" /etc/httpd/conf.d/z-ocsinventory-server.conf

OCS_DB_PWD_REPLACETEXT='PerlSetVar OCS_DB_PWD'
OCS_DB_PWD_NEW="\  PerlSetVar OCS_DB_PWD $ocsdbuserpassword"
sed -i "/$OCS_DB_PWD_REPLACETEXT/c $OCS_DB_PWD_NEW" /etc/httpd/conf.d/z-ocsinventory-server.conf


# modify zz-ocsinventory-restapi.conf with new database user password
OCS_DB_USER_RESTAPI_REPLACETEXT='{OCS_DB_USER} ='
OCS_DB_USER_RESTAPI_NEW="\  \$ENV{OCS_DB_USER} = 'ocs_dbuser';"
sed -i "/$OCS_DB_USER_RESTAPI_REPLACETEXT/c $OCS_DB_USER_RESTAPI_NEW" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf

OCS_DB_PWD_RESTAPI_REPLACETEXT='{OCS_DB_PWD} ='
OCS_DB_PWD_RESTAPI_NEW="\  \$ENV{OCS_DB_PWD} = 'zzreplaceholder';"
sed -i "/$OCS_DB_PWD_RESTAPI_REPLACETEXT/c $OCS_DB_PWD_RESTAPI_NEW" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf
sed -i "s/zzreplaceholder/$ocsdbuserpassword/" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf

# restart service
service httpd restart

firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --reload

echo -e "Installation complete, point your browser to http://server//ocsreports
|        to configure database server and create/update schema."
