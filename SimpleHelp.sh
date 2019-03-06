#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version simplehelp_version --service "initd, upstart, systemd or ignore"
# OR
# ./filename.sh -v version -s service

# default variables unless specified from command line
SIMPLEHELP_VERSION="5.0.20"

# set default service as suggested by SimpleHelp
if [ -f /sbin/initctl ]; then
   SERVICE_TYPE=upstart
elif [ -f /sbin/systemctl ]; then 
   SERVICE_TYPE=systemd
elif [ -f /bin/systemctl ]; then 
   SERVICE_TYPE=systemd
else
   SERVICE_TYPE=ignore
fi

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
        -v | --version )
            shift
            SIMPLEHELP_VERSION="$1"
            ;;
        -s | --service )
            shift
            SERVICE_TYPE="$1"
            ;;
    esac
    shift
done

# install prereqs
if [ $os_family = debian ]; then
  apt-get -y install wget
elif [ $os_family = fedora ]; then  
  yum -y install wget
else
  echo "unknown operating system family"
  exit 1
fi

# Generate a timestamp
now=$(date +"%Y%m%d_%H%M%S")

# Stop the server and backup current if exists at /opt/simplehelp
if [ -f /etc/init.d/simplehelp ]; then
  /etc/init.d/simplehelp stop
fi
if [ -f /etc/init/simplehelp.conf ]; then
  /sbin/initctl stop simplehelp
fi
if [ -f /etc/systemd/system/simplehelp.service ]; then
  systemctl stop simplehelp.service
fi
cd /opt
if [ -d "/opt/SimpleHelp" ]; then
  cd SimpleHelp
  sh serverstop.sh
  cd ..

  echo "Backing up the SimpleHelp installation to SimpleHelp_backup_$now"
  mv SimpleHelp "SimpleHelp_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# Fetch the new version
echo "Downloading the latest version"
if [ `uname -m | grep "64"` ]; then
    rm -f SimpleHelp-linux-amd64.tar.gz
    wget https://simple-help.com/releases/SimpleHelp-linux-amd64.tar.gz
    tar -xzf SimpleHelp-linux-amd64.tar.gz
else
    rm -f SimpleHelp-linux-tar.gz
    wget https://simple-help.com/releases/SimpleHelp-linux.tar.gz
    tar -xzf SimpleHelp-linux.tar.gz
fi

# Copy across the old configuration folder
if [ -d "/opt/SimpleHelp_backup_$now" ]; then
  echo "Copying across configuration files"
  cp -R /opt/SimpleHelp_backup_$now/configuration/* /opt/SimpleHelp/configuration
fi
	
# Copy across a legacy license file
if [ -f "/opt/SimpleHelp_backup_$now/shlicense.txt" ]; then
  cp /opt/SimpleHelp_backup_$now/shlicense.txt /opt/SimpleHelp/configuration
fi
	        
# Copy across any keystore file
if [ -f "/opt/SimpleHelp_backup_$now/keystore" ]; then
  cp /opt/SimpleHelp_backup_$now/keystore /opt/SimpleHelp
fi

# configure the service if specified
if [ $SERVICE_TYPE = initd ]; then
  wget https://simple-help.com/static/simplehelp-init.d -O /etc/init.d/simplehelp
  chkconfig --add /etc/init.d/simplehelp
  chkconfig /etc/init.d/simplehelp on
elif [ $SERVICE_TYPE = upstart ]; then
  wget https://simple-help.com/static/simplehelp-upstart.conf -O /etc/init/simplehelp.conf
  /sbin/initctl start simplehelp
elif [ $SERVICE_TYPE = systemd ]; then
  wget https://simple-help.com/static/simplehelp-systemd.service -O /etc/systemd/system/simplehelp.service
  systemctl daemon-reload
  systemctl enable simplehelp.service
  systemctl start simplehelp.service
else
  echo "service setup ignored"
fi
if [ $? -ne 0 ]; then
     echo "Failed to download service"   
     exit
fi

# start services
echo "Starting your new SimpleHelp server"
if [ -f /etc/init.d/simplehelp ]; then
  /etc/init.d/simplehelp start
elif [ -f /etc/init/simplehelp.conf ]; then
  /sbin/initctl start simplehelp
elif [ -f /etc/systemd/system/simplehelp.service ]; then
  systemctl start simplehelp.service
else
  cd SimpleHelp
  sh serverstart.sh
  cd ..
fi

echo "SimpleHelp $SIMPLEHELP_VERSION setup Complete https://simple-help.com/install---linux"
echo "The following service type was configured: $SERVICE_TYPE"

if [ $os_family = fedora ]; then
  # set selinux rule
  setsebool -P httpd_can_network_connect 1
  echo "    be sure to open firewall ports and allow through selinux, ex:"
  # open firewall ports
  echo "    firewall-cmd --permanent --add-port=80/tcp"
  echo "    firewall-cmd --permanent --add-port=80/udp"
  echo "    firewall-cmd --permanent --add-port=443/tcp"
  echo "    firewall-cmd --permanent --add-port=443/udp"
  echo "    firewall-cmd --reload"
fi
