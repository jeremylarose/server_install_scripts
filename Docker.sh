#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh
# OR
# ./filename.sh

# default variables unless specified from command line

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
  echo "unknown os codename"
  exit 1
fi

# Install Docker
if [ $os_family = debian ]; then
  apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/${os}/gpg | sudo apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${os} ${os_codename} stable"
  apt update
  apt -y install docker-ce docker-ce-cli containerd.io
elif [ $os_family = fedora ]; then
  echo "os not supported yet"
  exit
else
  echo "unknown operating system family"
  exit
fi

echo -e "Installation complete"
