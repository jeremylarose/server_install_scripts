#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version check_mk_version --sitename check_mk_site
# OR
# ./filename.sh -v version -s sitename

# default variables unless specified from command line
CHECK_MK_VERSION="1.5.0p3"
SITENAME="monitoring"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

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
  echo "unknown os codename"
  exit 1
fi

# define installer file
if [ $os_family = debian ]; then
  installer=check-mk-raw-${CHECK_MK_VERSION}_0.${os_codename}_amd64.deb
elif [ $os_family = fedora ]; then
  installer=check-mk-raw-${CHECK_MK_VERSION}-el7-38.x86_64.rpm
else
  echo "unknown operating system family"
  exit 1
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            CHECK_MK_VERSION="$1"
            ;;
        -s | --sitename )
            shift
            SITENAME="$1"
            ;;
    esac
    shift
done

# Download Check_MK Raw Install
wget https://mathias-kettner.de/support/${CHECK_MK_VERSION}/$installer

if [ $? -ne 0 ]; then
     echo "Failed to download $installer"   
     echo "https://mathias-kettner.de/support/${CHECK_MK_VERSION}/$installer"
     exit
fi

# Install Check_MK Raw Edition
if [ $os_family = debian ]; then
  dpkg -i $installer
  if [ $? -ne 0 ]; then
       apt -f -y install
       dpkg -i $installer
  fi
elif [ $os_family = fedora ]; then
  # open firewall ports
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --permanent --add-port=6556/tcp
  firewall-cmd --reload
  # set selinux rule
  setsebool -P httpd_can_network_connect 1 
  # Install prereqs
  yum -y install epel-release time traceroute dialog fping graphviz graphviz-gd libevent libdbi libmcrypt libtool-ltdl \
  rpcbind net-snmp net-snmp-utils pango patch perl-Net-SNMP perl-IO-Zlib uuid xinetd freeradius-utils \
  libpcap bind-utils poppler-utils libgsf rpm-build
  # install rpm
  rpm -i $installer
else
  echo "unknown operating system family"
  exit
fi


# If apt fails to exit
if [ $? -ne 0 ]; then
     echo "failed to install all required dependencies"
     exit
fi

# create and start "monitoring" site
omd create $SITENAME
omd start $SITENAME

echo -e "Installation complete"