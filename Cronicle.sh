#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --role masterorslave --host hostname_or_ip --secret_key secretkeyforserver --http_port httportdefault3012 --cronicle_version version
# OR
# ./filename.sh -r masterorslave -h hostname.com -s secret_key -p http_port -v version

# set default variables
cronicle_version='0.8.42'
http_port='3012'
host='localhost'

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
  os_codename='unknown'
fi

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -r | --role )
            shift
            role="$1"
            ;;
        -h | --host )
            shift
            host="$1"
            ;;
        -s | --secret_key )
            shift
            secret_key="$1"
            ;;
        -p | --http_port )
            shift
            http_port="$1"
            ;;              
        -v | --cronicle_version )
            shift
            cronicle_version="$1"
            ;;
esac
    shift
done

# Get information from terminal if not provided as arguments:
if [ -z "$secret_key" ]; then
    echo 
    while true
    do
        read -s -p "Enter a secret key to be used for cronicle (32 characters plus recommended): " secret_key
        echo
        read -s -p "Confirm secret key: " secret_key2
        echo
        [ "$secret_key" = "$secret_key2" ] && break
        echo "Keys don't match. Please try again."
        echo
    done
fi

if [ -z "$role" ]; then
    echo
    read -p "Enter the role of this Cronicle installation (master or slave?): " role
    echo
fi

# install nodejs and components
if [ $os_family = debian ]; then

	# install dependencies
	apt -y install curl apt-transport-https lsb-release

	# install NodeJS
	curl -sL https://deb.nodesource.com/setup_8.x | bash -
	apt -y install nodejs
	
elif [ $os_family = fedora ]; then

	# Install NodeJS(centos/rhel version 7 or higher)
	curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
	yum -y install nodejs tar

fi

# install cronicle
  mkdir -p /opt/cronicle
  cd /opt/cronicle
  curl -L https://github.com/jhuckaby/Cronicle/archive/v${cronicle_version}.tar.gz | tar zxvf - --strip-components 1
  npm install
  node bin/build.js dist

# input specified options
HOST_REPLACETEXT='"base_app_url":'
HOST_NEW='\        "base_app_url": "http://zreplaceholder:3012",'
sed -i "/$HOST_REPLACETEXT/c $HOST_NEW" /opt/cronicle/conf/config.json
sed -i "s/zreplaceholder/$host/" /opt/cronicle/conf/config.json

KEY_REPLACETEXT='"secret_key":'
KEY_NEW='\        "secret_key": "zzreplaceholder",'
sed -i "/$KEY_REPLACETEXT/c $KEY_NEW" /opt/cronicle/conf/config.json
sed -i "s/zzreplaceholder/$secret_key/" /opt/cronicle/conf/config.json

PORT_REPLACETEXT='"http_port":'
PORT_NEW='\                "http_port": zzzreplaceholder,'
sed -i "/$PORT_REPLACETEXT/c $PORT_NEW" /opt/cronicle/conf/config.json
sed -i "s/zzzreplaceholder/$http_port/" /opt/cronicle/conf/config.json

# setup master if role specified
  if [ "$role" = master ]; then  
  /opt/cronicle/bin/control.sh setup
  fi

# create systemd service and start cronicle
if [[ -e /etc/systemd/system/ ]]; then
cat <<-EOF >/etc/systemd/system/cronicle.service
[Install]
WantedBy=multi-user.target

[Service]
Type=forking
PIDFile=/opt/cronicle/logs/cronicled.pid
ExecStart=/opt/cronicle/bin/control.sh start
ExecStop=/opt/cronicle/bin/control.sh stop
EOF
fi

systemctl daemon-reload
systemctl enable cronicle.service
systemctl enable cronicle.service

service cronicle start

# temporarily open firewall for fedora
if [ $os_family = fedora ]; then
  echo "be sure to open firewall ports, example:"
  # temporarily open firewall (don't forget to restrict)
  echo "firewall-cmd --permanent --add-port=${http_port}/tcp"
  echo "firewall-cmd --reload"
fi
