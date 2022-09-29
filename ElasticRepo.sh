#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version "version#"
# ./filename.sh -v elasticversion

# set default variables
elasticversion="8.4.2"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
	os_family=$os
else
	os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --elasticversion )
            shift
            elasticversion="$1"
            ;;
esac
    shift
done

# set more variables for download links
elasticversion_major=`echo "$elasticversion" | cut -d. -f-2`
elasticversion_majormajor=`echo "$elasticversion" | cut -d. -f-1`

# install wazuh
if [ $os_family = debian ]; then

	# install dependencies
	apt -y install curl apt-transport-https lsb-release

    # add elastic repository
    curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    echo "deb https://artifacts.elastic.co/packages/${elasticversion_majormajor}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${elasticversion_majormajor}.x.list
   
    # install elasticsearch and kibana
    apt update

elif [ $os_family = fedora ]; then
    
	# add elastic repository and GPG key
	rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
	
	cat <<-EOF >/etc/yum.repos.d/elastic.repo
	[elasticsearch-${elasticversion_majormajor}.x]
	name=Elasticsearch repository for ${elasticversion_majormajor}.x packages
	baseurl=https://artifacts.elastic.co/packages/${elasticversion_majormajor}.x/yum
	gpgcheck=1
	gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
	enabled=1
	autorefresh=1
	type=rpm-md
	EOF
fi
