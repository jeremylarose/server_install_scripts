#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version check_mk_version --codename os_codename --sitename check_mk_site
# OR
# ./filename.sh -v version -c codename -s sitename

# default variables unless specified from command line
CHECK_MK_VERSION="1.5.0p3"
CODENAME="el7"
SITENAME="monitoring"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            CHECK_MK_VERSION="$1"
            ;;
        -c | --codename )
            shift
            CODENAME="$1"
            ;;
        -s | --sitename )
            shift
            SITENAME="$1"
            ;;
    esac
    shift
done

# Install prereqs
yum -y install epel-release time traceroute dialog fping graphviz graphviz-gd libevent libdbi libmcrypt libtool-ltdl \
rpcbind net-snmp net-snmp-utils pango patch perl-Net-SNMP perl-IO-Zlib uuid xinetd freeradius-utils \
libpcap bind-utils poppler-utils libgsf rpm-build

# If yum fails to run completely the rest of this isn't going to work...
if [ $? -ne 0 ]; then
     echo "yum failed to install all required dependencies"
     exit
fi

# Download Check_MK Raw Install
wget https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}-$CODENAME-38.x86_64.rpm

if [ $? -ne 0 ]; then
     echo "Failed to download check-mk-raw-${CHECK_MK_VERSION}.tar.gz"   
     echo "https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}-$CODENAME-38.x86_64.rpm"
     exit
fi

# Install Check_MK Raw Edition
rpm -i check-mk-raw-${CHECK_MK_VERSION}-$CODENAME-38.x86_64.rpm

# create and start "monitoring" site
omd create $SITENAME
omd start $SITENAME

# open firewall ports
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=6556/tcp
firewall-cmd --reload

# set selinux rule
setsebool -P httpd_can_network_connect 1

echo -e "Installation complete"
