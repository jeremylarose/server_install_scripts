#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --saltgui_user username --saltgui_pwd password --salt_version saltversionnumber --saltgui_version saltguiversionnumber
# OR
# ./filename.sh -u username -p password -v saltversionnumber --g saltguiversionnumber

saltgui_version="1.3.0"
salt_version="2018.3"

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
while [ "$1" != "" ]; do
    case $1 in
        -u | --saltgui_user )
            shift
            saltgui_user="$1"
            ;;
        -p | --saltgui_pwd )
            shift
            saltgui_pwd="$1"
            ;;
        -v | --salt_version )
            shift
            salt_version="$1"
            ;;
        -g | --saltgui_version )
            shift
            saltgui_version="$1"
            ;;
    esac
    shift
done

# Get SaltGUI initial username and password
if [ -n "$saltgui_user" ] && [ -n "$saltgui_pwd" ]; then
        saltguiusername=$saltgui_user
        saltguipassword=$saltgui_pwd
else
    echo 
    while true
    do
        read -p "Enter the first SaltGUI username: " saltguiusername
        break
        echo
    done
    echo
    while true
    do
        read -s -p "Enter SaltGUI password: " saltguipassword
        echo
        read -s -p "Confirm SaltGUI Password: " password2
        echo
        [ "$saltguipassword" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# install latest salt items from http://repo.saltstack.com
if [ $os_family = debian ]; then
	wget -O - https://repo.saltstack.com/apt/${os}/${osversion}/amd64/${salt_version}/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
	echo "deb http://repo.saltstack.com/apt/${os}/${osversion}/amd64/${salt_version} ${os_codename} main" > /etc/apt/sources.list.d/saltstack.list
	apt update
	apt -y install salt-master salt-api
elif [ $os_family = fedora ]; then  
	yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-${salt_version}-1.el${osversion}.noarch.rpm
	yum -y clean expire-cache
	yum -y install salt-master salt-api
else
  echo "unknown operating system family"
  exit 1
fi


# install saltgui from https://github.com/erwindon/SaltGUI

# download SaltGUI
wget -O SaltGUI-${saltgui_version}.tar.gz https://github.com/erwindon/SaltGUI/archive/${saltgui_version}.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download SaltGUI_${saltgui_version}.tar.gz"
    echo "https://github.com/erwindon/SaltGUI/archive/${saltgui_version}.tar.gz"
    exit
fi

# Extract SaltGUI files
tar -xzf SaltGUI-${saltgui_version}.tar.gz

# copy saltgui folder to proper location
mkdir -p /srv
cp -rf SaltGUI-${saltgui_version}/saltgui /srv
rm rf SaltGUI-${saltgui_version}*

# add salt master config for cherrypy authentication with pam
cat > /etc/salt/master.d/saltgui.conf << EOF
external_auth:
  pam:
    saltgui_admin%:
      - .*
      - '@runner'
      - '@wheel'
      - '@jobs'

rest_cherrypy:
  port: 3333
  host: 0.0.0.0
  disable_ssl: True
  app: /srv/saltgui/index.html
  static: /srv/saltgui/static
  static_path: /static
EOF

# create saltgui_admin pam group if doesn't exist
getent group saltgui_admin || groupadd saltgui_admin

# create local pam user if doesn't exist
id -u $saltguiusername &>/dev/null || useradd $saltguiusername && 

# set password for local pam user
echo $saltguiusername:$saltguipassword | /usr/sbin/chpasswd

# add user to salt master acl with permissions for salt gui
usermod -a -G saltgui_admin $saltguiusername

service salt-master restart
service salt-api restart

echo -e "Installation complete, point your browser to http://server:3333
|        to logon with $saltguiusername and the password you specified."
