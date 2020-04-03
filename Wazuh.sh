#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --wazuhversion "wazuhversion#" --elkversion "elkversion#" --elasticsearch_server "localhost"
# ./filename.sh -v wazuhversion -e elkversion -l elasticsearchserver

# set default variables
wazuhversion="3.11.4"
elkversion="7.6.1"
elasticsearch_server="localhost"

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
        -v | --wazuhversion )
            shift
            wazuhversion="$1"
            ;;
        -e | --elkversion )
            shift
            elkversion="$1"
            ;;
        -l | --elasticsearch_server )
            shift
            elasticsearch_server="$1"
            ;;
esac
    shift
done

# set more variables for download links
wazuhversion_major=`echo "$wazuhversion" | cut -d. -f-2`
wazuhversion_majormajor=`echo "$wazuhversion" | cut -d. -f-1`
elkversion_major=`echo "$elkversion" | cut -d. -f-2`
elkversion_majormajor=`echo "$elkversion" | cut -d. -f-1`

# install wazuh
if [ $os_family = debian ]; then

	# install dependencies
	apt -y install curl apt-transport-https lsb-release

	#create symlink for python if /usr/bin/python bath doesn't exist
	if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi

	# Install GPG key
	curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -

	# add wazuh repository
	echo "deb https://packages.wazuh.com/${wazuhversion_majormajor}.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list

	# update packages and install wazuh manager
	apt update
	apt -y install wazuh-manager

	# install NodeJS for wazuh api and then wazuh api
        apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
        curl -sL https://deb.nodesource.com/setup_10.x | sudo bash
        apt update
	apt -y install nodejs wazuh-api
	
	# disable wazuh updates
	sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
	
elif [ $os_family = fedora ]; then

	# add Wazuh repo for centos
	cat <<-EOF >/etc/yum.repos.d/wazuh.repo
	[wazuh_repo]
	gpgcheck=1
	gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
	enabled=1
	name=Wazuh repository
	baseurl=https://packages.wazuh.com/${wazuhversion_majormajor}.x/yum/
	protect=1
	EOF

	# Insall Wazuh Manager
	yum -y install wazuh-manager

	# Install NodeJS and Wazuh API (centos/rhel version 7 or higher)
        curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
	yum -y install nodejs wazuh-api
        
	# disable wazuh repository
	sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo
fi

# install filebeat
	if [ $os_family = debian ]; then

		curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
		echo "deb https://artifacts.elastic.co/packages/${elkversion_majormajor}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${elkversion_majormajor}.x.list
		apt-get update
                apt -y install filebeat=${elkversion}
                
		# disable elasticstack updates
		sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-${elkversion_majormajor}.x.list
		apt update
		
	elif [ $os_family = fedora ]; then

		# add elk repository and GPG key
		rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
		cat <<-EOF >/etc/yum.repos.d/elastic.repo
		[elasticsearch-${elkversion_majormajor}.x]
		name=Elasticsearch repository for ${elkversion_majormajor}.x packages
		baseurl=https://artifacts.elastic.co/packages/${elkversion_majormajor}.x/yum
		gpgcheck=1
		gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
		enabled=1
		autorefresh=1
		type=rpm-md
		EOF

		# install filebeat
		yum -y install filebeat-${elkversion}
		
		# disable elasticstack updates
		sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/elastic.repo

	fi
    
 # download filebeat config and set server address/ip if specified

    curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/v${wazuhversion}/extensions/filebeat/${elkversion_majormajor}.x/filebeat.yml
    sed -i "s/YOUR_ELASTIC_SERVER_IP/$elasticsearch_server/" /etc/filebeat/filebeat.yml

    systemctl daemon-reload
    systemctl enable filebeat.service
    systemctl start filebeat.service

# Download alerts template for elasticsearch after 60 seconds and load filebeat template
sleep 60

chmod go+r /etc/filebeat/wazuh-template.json
filebeat setup --index-management -E setup.template.json.enabled=false
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v${wazuhversion}/extensions/elasticsearch/${elkversion_majormajor}.x/wazuh-template.json

# download wazuh module for filebeat
 curl -s https://packages.wazuh.com/${wazuhversion_majormajor}.x/filebeat/wazuh-filebeat-0.1.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module

# ensure proper permissions for kibana app
if [[ -e /usr/share/kibana/bin/kibana-plugin ]]; then
	chown -R kibana:kibana /usr/share/kibana/optimize
	chown -R kibana:kibana /usr/share/kibana/plugins
fi

# remove previous version of kibana wazuh plugin if installed
if [[ -e /usr/share/kibana/plugins/wazuh ]]; then
        cd /usr/share/kibana/plugins
	sudo -u kibana /usr/share/kibana/bin/kibana-plugin remove wazuh
	rm -rf /usr/share/kibana/optimize/bundles
fi

# increase Node.js heap memory and install Wazuh app plugin for kibana as kibana if kibana is installed
if [[ -e /usr/share/kibana/bin/kibana-plugin ]]; then
        cd /usr/share/kibana/plugins
	cat >> /etc/default/kibana << EOF
        NODE_OPTIONS="--max_old_space_size=2048"
        EOF
	export NODE_OPTIONS="--max-old-space-size=2048" && sudo -u kibana /usr/share/kibana/bin/kibana-plugin install -b https://packages.wazuh.com/wazuhapp/wazuhapp-${wazuhversion}_${elkversion}.zip
fi
