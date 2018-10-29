#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --saltgui_user username --saltgui_pwd password --version saltguiversionnumber
# OR
# ./filename.sh -u username -p password -v saltguiversionnumber

saltgui_version="1.4.0"

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
        -v | --version )
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
rm -rf SaltGUI-${saltgui_version}*

# add salt master config for cherrypy authentication with pam
cat > /etc/salt/master.d/saltgui.conf << EOF
external_auth:
  pam:
    saltgui_admin%:
      - .*
      - '@runner'
      - '@wheel'
      - '@jobs'
    saltgui_keymaster%:
      - grains.items
      - sys.doc
      - state.apply
      - '@wheel':
        - 'key.*'
    saltgui_installer%:
      - grains.items
      - sys.doc
      - state.apply
      - pkg.*
      - '@wheel':
        - 'key.list'
    saltgui_minimal%:
      - grains.items
      - sys.doc
      - state.apply
      - '@wheel':
        - 'key.list'

rest_cherrypy:
  port: 3333
  host: 0.0.0.0
  disable_ssl: True
  app: /srv/saltgui/index.html
  static: /srv/saltgui/static
  static_path: /static
EOF

# create saltgui pam groups if don't exist
getent group saltgui_admin || groupadd saltgui_admin
getent group saltgui_keymaster || groupadd saltgui_keymaster
getent group saltgui_installer || groupadd saltgui_installer
getent group saltgui_minimal || groupadd saltgui_minimal

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
