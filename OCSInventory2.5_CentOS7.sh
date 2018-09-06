#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --ocsdbuser username --ocsdbpwd password --ocsdbhost hostname --ocsversion version
# OR
# ./filename.sh -u username -p password -h hostname -v version

# install mysql or mariadb seperately (ex: ./MariaDB_CentOS.sh -r rootpassword -n ocsweb -u ocsdbuser -p dbpassword)

# OCS Inventory defaults unless specified
ocsversion="2.5"
ocsdbhost="localhost"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -u | --ocsdbuser )
            shift
            ocsdbuser="$1"
            ;;
        -p | --ocsdbpwd )
            shift
            ocsdbpwd="$1"
            ;;
        -h | --ocsdbhost )
            shift
            ocsdbhost="$1"
            ;;
        -v | --ocsversion )
            shift
            ocsversion="$1"
            ;;
    esac
    shift
done

if [ -z "$ocsdbuser" ]; then
    echo
    read -p "Enter the OCS Inventory database username with access: " ocsdbuser
    echo
fi
if [ -z "$ocsdbpwd" ]; then
    echo
    while true
    do
        read -s -p "Enter the OCS Inventory User Database Password: " ocsdbpwd
        echo
        read -s -p "Confirm the OCS Inventory User Database Password: " password2
        echo
        [ "$ocsdbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi


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
wget -O OCSNG_UNIX_SERVER_${ocsversion}.tar.gz https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${ocsversion}/OCSNG_UNIX_SERVER_${ocsversion}.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download OCSNG_UNIX_SERVER_${ocsversion}.tar.gz"
    echo "https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${ocsversion}/OCSNG_UNIX_SERVER_${ocsversion}.tar.gz"
    exit
fi

# Extract OCS Inventory files
tar -xzf OCSNG_UNIX_SERVER_${ocsversion}.tar.gz

# modify setup.sh with new database user
DB_SERVER_USER_REPLACETEXT="DB_SERVER_USER="
DB_SERVER_USER_NEW=DB_SERVER_USER="$ocsdbuser"
sed -i "/$DB_SERVER_USER_REPLACETEXT/c $DB_SERVER_USER_NEW" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# modify setup.sh with new database user password
DB_SERVER_PWD_REPLACETEXT="DB_SERVER_PWD="
DB_SERVER_PWD_NEW=DB_SERVER_USER="$ocsdbpwd"
sed -i "/$DB_SERVER_PWD_REPLACETEXT/c $DB_SERVER_PWD_NEW" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# modify setup.sh with new database host
DB_SERVER_HOST_REPLACETEXT="DB_SERVER_HOST="
DB_SERVER_HOST_NEW=DB_SERVER_HOST="$ocsdbhost"
sed -i "/$DB_SERVER_HOST_REPLACETEXT/c $DB_SERVER_HOST_NEW" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# modifify setup.sh continuing on error
FORCECONTINUE_REPLACETEXT='exit 1'
FORCECONTINUE='echo "error but continuing"'
sed -i "s/$FORCECONTINUE_REPLACETEXT/$FORCECONTINUE" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# run unattended setup script
cd OCSNG_UNIX_SERVER_${ocsversion}
yes "" | sh setup.sh

# modify z-ocsinventory-server.conf with new database user and password replacing lines
OCS_DB_USER_REPLACETEXT='PerlSetEnv OCS_DB_USER'
OCS_DB_USER_NEW="\  PerlSetEnv OCS_DB_USER $ocsdbuser"
sed -i "/$OCS_DB_USER_REPLACETEXT/c $OCS_DB_USER_NEW" /etc/httpd/conf.d/z-ocsinventory-server.conf

OCS_DB_PWD_REPLACETEXT='PerlSetVar OCS_DB_PWD'
OCS_DB_PWD_NEW="\  PerlSetVar OCS_DB_PWD $ocsdbpwd"
sed -i "/$OCS_DB_PWD_REPLACETEXT/c $OCS_DB_PWD_NEW" /etc/httpd/conf.d/z-ocsinventory-server.conf

OCS_DB_HOST_REPLACETEXT='PerlSetEnv OCS_DB_HOST'
OCS_DB_HOST_NEW="\  PerlSetEnv OCS_DB_HOST $ocsdbhost"
sed -i "/$OCS_DB_HOST_REPLACETEXT/c $OCS_DB_HOST_NEW" /etc/httpd/conf.d/z-ocsinventory-server.conf

# modify zz-ocsinventory-restapi.conf with new database user password and host
OCS_DB_USER_RESTAPI_REPLACETEXT='{OCS_DB_USER} ='
OCS_DB_USER_RESTAPI_NEW="\  \$ENV{OCS_DB_USER} = 'zreplaceholder';"
sed -i "/$OCS_DB_USER_RESTAPI_REPLACETEXT/c $OCS_DB_USER_RESTAPI_NEW" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbuser/" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf

OCS_DB_PWD_RESTAPI_REPLACETEXT='{OCS_DB_PWD} ='
OCS_DB_PWD_RESTAPI_NEW="\  \$ENV{OCS_DB_PWD} = 'zzreplaceholder';"
sed -i "/$OCS_DB_PWD_RESTAPI_REPLACETEXT/c $OCS_DB_PWD_RESTAPI_NEW" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf
sed -i "s/zzreplaceholder/$ocsdbpwd/" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf

OCS_DB_HOST_RESTAPI_REPLACETEXT='{OCS_DB_HOST} ='
OCS_DB_HOST_RESTAPI_NEW="\  \$ENV{OCS_DB_HOST} = 'zreplaceholder';"
sed -i "/$OCS_DB_HOST_RESTAPI_REPLACETEXT/c $OCS_DB_HOST_RESTAPI_NEW" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbhost/" /etc/httpd/conf.d/zz-ocsinventory-restapi.conf


# set permissions
chown -R apache:apache /usr/share/ocsinventory-reports/
chown -R apache:apache /var/lib/ocsinventory-reports/
find /usr/share/ocsinventory-reports/ocsreports/ -type f -exec chmod 0644 {} \;
find /usr/share/ocsinventory-reports/ocsreports/ -type d -exec chmod 0755 {} \;
chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports
chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports/upload
chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php

# restart service
service httpd restart

# open firewall port (optional)
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

echo -e "Installation complete, point your browser to http://server//ocsreports
|        to configure database server and create/update schema."
