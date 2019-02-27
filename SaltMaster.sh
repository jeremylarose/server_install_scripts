#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh -v saltversionnumber -c saltcomponent1 -c saltcomponent2..etc...

# set default version
salt_version="2019.2"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os version from system
osversion=`cat /etc/*release | grep ^VERSION_ID= | cut -d= -f2 | sed 's/\"//g'`

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
while getopts ":v:c:" opt; do
  case "$opt" in
    v) salt_version=$OPTARG ;;
    c) salt_components+=("$OPTARG") ;;
  esac
done
shift $((OPTIND -1))

# install latest salt items from http://repo.saltstack.com
if [ $os_family = debian ]; then
	wget -O - https://repo.saltstack.com/py3/${os}/${osversion}/amd64/${salt_version}/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
	echo "deb http://repo.saltstack.com/py3/${os}/${osversion}/amd64/${salt_version} ${os_codename} main" > /etc/apt/sources.list.d/saltstack.list
	apt update
	apt -y install salt-master
	for salt_component in "${salt_components[@]}"; do
		apt -y install ${salt_component}
	done
elif [ $os_family = fedora ]; then  
	yum -y install https://repo.saltstack.com/py3/redhat/salt-py3-repo-${salt_version}-1.el${osversion}.noarch.rpm
	yum -y clean expire-cache
	yum -y install salt-master
	for salt_component in "${salt_components[@]}"; do
		yum -y install ${salt_component}
	done
else
  echo "unknown operating system family"
  exit 1
fi

echo
echo "Installation complete: salt-master ${salt_components[*]}"
echo
