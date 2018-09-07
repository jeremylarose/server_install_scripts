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

# get os_codename from system
if [ $os = debian ] || [ $os = centos ] || [ $os = rhel ]; then
  os_codename=`cat /etc/*release | grep ^VERSION= | cut -d'(' -f2 | cut -d')' -f1 | awk '{print tolower($0)}'`
elif [ $os = ubuntu ]; then
  os_codename=`cat /etc/*release | grep ^DISTRIB_CODENAME= | cut -d= -f2`
else
  echo "unknown os codename"
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
wget https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}_0.${os_codename}_amd64.deb

if [ $? -ne 0 ]; then
     echo "Failed to download check-mk-raw-${CHECK_MK_VERSION}.deb"   
     echo "https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}_0.${os_codename}_amd64.deb"
     exit
fi

# Install Check_MK Raw Edition (2 attempts)
dpkg -i check-mk-raw-${CHECK_MK_VERSION}_0.${os_codename}_amd64.deb
if [ $? -ne 0 ]; then
     apt -f -y install
     dpkg -i check-mk-raw-${CHECK_MK_VERSION}_0.${os_codename}_amd64.deb
fi

# If apt fails to run completely the rest of this isn't going to work...
if [ $? -ne 0 ]; then
     echo "apt-get failed to install all required dependencies"
     exit
fi

# create and start "monitoring" site
omd create $SITENAME
omd start $SITENAME

echo -e "Installation complete"
