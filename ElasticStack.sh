#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version "version#" --heapsize "size of jvm heap"
# ./filename.sh -v elkversion -h "size of heap"

# set default variables
elkversion="7.5.1"
heap_size="1g"

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
        -v | --elkversion )
            shift
            elkversion="$1"
            ;;
        -h | --heapsize )
            shift
            heap_size="$1"
            ;;
esac
    shift
done

# set more variables for download links
elkversion_major=`echo "$elkversion" | cut -d. -f-2`
elkversion_majormajor=`echo "$elkversion" | cut -d. -f-1`

# install wazuh
if [ $os_family = debian ]; then

	# install dependencies
	apt -y install curl apt-transport-https lsb-release

    # add elastic repository
    curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    echo "deb https://artifacts.elastic.co/packages/${elkversion_majormajor}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${elkversion_majormajor}.x.list
   
    # install elasticsearch and kibana
    apt update
    apt -y install elasticsearch=${elkversion} kibana=${elkversion}

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

	# install elasticsearch and kibana
	yum -y install elasticsearch-${elkversion} kibana-${elkversion}
fi

# enable elk services for systemd
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
systemctl enable kibana.service
systemctl start kibana.service

# allow kibana to be open to other machines from port 5601 (be sure to lock down with firewall / https proxy)
KIBANA_REPLACETEXT='server.host:'
KIBANA_NEW='server.host: "0.0.0.0"'
sed -i "/$KIBANA_REPLACETEXT/c $KIBANA_NEW" /etc/kibana/kibana.yml

## Elasticsearch tuning ##

# lock memory on startup prevent system memory swap with Elasticsearch by uncommenting it
sed -i '/bootstrap.memory_lock/s/^#//g' /etc/elasticsearch/elasticsearch.yml

# Edit system resources limit in elasticsearch
if [[ -e /etc/systemd/system/ ]]; then
	mkdir -p /etc/systemd/system/elasticsearch.service.d/
	cat <<-EOF >/etc/systemd/system/elasticsearch.service.d/elasticsearch.conf
	[Service]
	LimitMEMLOCK=infinity
	EOF
fi
if [[ -e /etc/sysconfig/elasticsearch ]]; then
	sed -i '/MAX_LOCKED_MEMORY/s/^#//g' /etc/sysconfig/elasticsearch
elif [[ -e /etc/default/elasticsearch ]]; then
	sed -i '/MAX_LOCKED_MEMORY/s/^#//g' /etc/default/elasticsearch
fi

# Limit memory by setting Elasticsearch heap size (use no more than half of your available memory and 32gb max)
sed -i "s/^-Xms.*$/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sed -i "s/^-Xmx.*$/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

systemctl daemon-reload
service elasticsearch restart
service kibana restart
