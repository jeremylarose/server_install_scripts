#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --dbuser username --dbpwd password --dbhost hostname --dbhostportnumber portnumber --version version
# OR
# ./filename.sh -u username -p password -h hostname -n hostportnumber -v version

# install mysql or mariadb seperately (ex: ./MariaDB.sh -r rootpassword -d ocsweb -u ocs_dbuser -p dbpassword)

# OCS Inventory defaults unless specified with command line argument
ocsversion="2.5"
ocsdbhost="localhost"
ocsdbhostport="3306"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# define apache/httpd config files location
if [ $os_family = debian ]; then
  httpconfiglocation=/etc/apache2/conf-available
elif [ $os_family = fedora ]; then
  httpconfiglocation=/etc/httpd/conf.d
else
  echo "unknown operating system family"
  exit 1
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -u | --dbuser )
            shift
            ocsdbuser="$1"
            ;;
        -p | --dbpwd )
            shift
            ocsdbpwd="$1"
            ;;
        -h | --dbhost )
            shift
            ocsdbhost="$1"
            ;;
        -n | --dbhostportnumber )
            shift
            ocsdbhostport="$1"
            ;;
        -v | --version )
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

# Install prereqs
if [ $os_family = debian ]; then
  apt-get -y install php-curl apache2-dev gcc perl-modules-5.26 make apache2 php perl libapache2-mod-perl2 libapache2-mod-php \
  libio-compress-perl libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libsoap-lite-perl libnet-ip-perl php-mysql \
  php-gd php7.2-dev php-mbstring php-soap php-xml php-pclzip libarchive-zip-perl php7.2-zip cpanminus
elif [ $os_family = fedora ]; then
  yum -y install epel-release
  # Install more prereqs
  yum install -y php-curl httpd httpd-devel gcc mod_perl mod_php mod_ssl make perl-XML-Simple perl-Compress-Zlib perl-DBI \
  perl-DBD-MySQL perl-Net-IP perl-SOAP-Lite perl-Archive-Zip php-common php-gd php-mbstring php-soap php-mysql php-ldap \
  php-xml cpanminus
  # enable and start httpd
  systemctl enable httpd
  systemctl start httpd
else
  echo "unknown operating system family"
  exit 1
fi

# install cpan modules
cpanm Apache2::SOAP

cpanm XML::Entities

cpanm Net::IP

cpanm Apache::DBI

cpanm Mojolicious::Lite

cpanm Switch

cpanm Plack::Handler

# If any installs fail, exit
if [ $? -ne 0 ]; then
    echo "failed to install all required dependencies"
    exit
fi

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

# modify setup.sh with new database port
DB_SERVER_PORT_REPLACETEXT="DB_SERVER_PORT="
DB_SERVER_PORT_NEW=DB_SERVER_HOST="$ocsdbhostport"
sed -i "/$DB_SERVER_PORT_REPLACETEXT/c $DB_SERVER_PORT_NEW" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# modifify setup.sh continuing on error
FORCECONTINUE_REPLACETEXT='exit 1'
FORCECONTINUE='echo "error but continuing"'
sed -i "s/$FORCECONTINUE_REPLACETEXT/$FORCECONTINUE/" OCSNG_UNIX_SERVER_${ocsversion}/setup.sh

# run unattended setup script
cd OCSNG_UNIX_SERVER_${ocsversion}
yes "" | sh setup.sh

# enable Apache configuration with aliases
if [ $os_family = debian ]; then
  if [ ! -e "$httpconfiglocation/ocsinventory-reports.conf" ]
  then
	  ln -s $httpconfiglocation/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
	  :
  fi
  if [ ! -e "$httpconfiglocation/z-ocsinventory-server.conf" ]
  then
      ln -s $httpconfiglocation/z-ocsinventory-server.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
	  :
  fi
  if [ ! -e "$httpconfiglocation/zz-ocsinventory-restapi.conf" ]
  then
	  ln -s $httpconfiglocation/zz-ocsinventory-restapi.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
	  :
  fi
fi

# temporarily open firewall for fedora
if [ $os_family = fedora ]; then
  firewall-cmd --permanent --add-port=3000/tcp
  firewall-cmd --reload
fi

# modify z-ocsinventory-server.conf with new database user and password replacing lines
OCS_DB_USER_REPLACETEXT='PerlSetEnv OCS_DB_USER'
OCS_DB_USER_NEW="\  PerlSetEnv OCS_DB_USER $ocsdbuser"
sed -i "/$OCS_DB_USER_REPLACETEXT/c $OCS_DB_USER_NEW" $httpconfiglocation/z-ocsinventory-server.conf

OCS_DB_PWD_REPLACETEXT='PerlSetVar OCS_DB_PWD'
OCS_DB_PWD_NEW="\  PerlSetVar OCS_DB_PWD $ocsdbpwd"
sed -i "/$OCS_DB_PWD_REPLACETEXT/c $OCS_DB_PWD_NEW" $httpconfiglocation/z-ocsinventory-server.conf

OCS_DB_HOST_REPLACETEXT='PerlSetEnv OCS_DB_HOST'
OCS_DB_HOST_NEW="\  PerlSetEnv OCS_DB_HOST $ocsdbhost"
sed -i "/$OCS_DB_HOST_REPLACETEXT/c $OCS_DB_HOST_NEW" $httpconfiglocation/z-ocsinventory-server.conf

OCS_DB_PORT_REPLACETEXT='PerlSetEnv OCS_DB_PORT'
OCS_DB_PORT_NEW="\  PerlSetEnv OCS_DB_PORT $ocsdbhostport"
sed -i "/$OCS_DB_PORT_REPLACETEXT/c $OCS_DB_PORT_NEW" $httpconfiglocation/z-ocsinventory-server.conf

# modify zz-ocsinventory-restapi.conf with new database user password and host
OCS_DB_USER_RESTAPI_REPLACETEXT='{OCS_DB_USER} ='
OCS_DB_USER_RESTAPI_NEW="\  \$ENV{OCS_DB_USER} = 'zreplaceholder';"
sed -i "/$OCS_DB_USER_RESTAPI_REPLACETEXT/c $OCS_DB_USER_RESTAPI_NEW" $httpconfiglocation/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbuser/" $httpconfiglocation/zz-ocsinventory-restapi.conf

OCS_DB_PWD_RESTAPI_REPLACETEXT='{OCS_DB_PWD} ='
OCS_DB_PWD_RESTAPI_NEW="\  \$ENV{OCS_DB_PWD} = 'zreplaceholder';"
sed -i "/$OCS_DB_PWD_RESTAPI_REPLACETEXT/c $OCS_DB_PWD_RESTAPI_NEW" $httpconfiglocation/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbpwd/" $httpconfiglocation/zz-ocsinventory-restapi.conf

OCS_DB_HOST_RESTAPI_REPLACETEXT='{OCS_DB_HOST} ='
OCS_DB_HOST_RESTAPI_NEW="\  \$ENV{OCS_DB_HOST} = 'zreplaceholder';"
sed -i "/$OCS_DB_HOST_RESTAPI_REPLACETEXT/c $OCS_DB_HOST_RESTAPI_NEW" $httpconfiglocation/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbhost/" $httpconfiglocation/zz-ocsinventory-restapi.conf

OCS_DB_PORT_RESTAPI_REPLACETEXT='{OCS_DB_PORT} ='
OCS_DB_PORT_RESTAPI_NEW="\  \$ENV{OCS_DB_PORT} = 'zreplaceholder';"
sed -i "/$OCS_DB_PORT_RESTAPI_REPLACETEXT/c $OCS_DB_PORT_RESTAPI_NEW" $httpconfiglocation/zz-ocsinventory-restapi.conf
sed -i "s/zreplaceholder/$ocsdbhostport/" $httpconfiglocation/zz-ocsinventory-restapi.conf


# set permissions and restart service
if [ $os_family = debian ]; then
  chown -R www-data:www-data /var/lib/ocsinventory-reports
  service apache2 restart
elif [ $os_family = fedora ]; then
  chown -R apache:apache /usr/share/ocsinventory-reports/
  chown -R apache:apache /var/lib/ocsinventory-reports/
  find /usr/share/ocsinventory-reports/ocsreports/ -type f -exec chmod 0644 {} \;
  find /usr/share/ocsinventory-reports/ocsreports/ -type d -exec chmod 0755 {} \;
  chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports
  chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports/upload
  chcon -t httpd_sys_rw_content_t /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php
  service httpd restart
else
  echo "unknown operating system family"
  exit 1
fi

echo -e "Installation complete, point your browser to http://server//ocsreports
|        to configure database server and create/update schema."
