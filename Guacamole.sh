#!/bin/bash

# install mysql or mariadb seperately (ex: ./MariaDB.sh -r rootpassword -d gitea - u gitea -p dbpassword)

# Version numbers
GUAC_VERSION="0.9.14"

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

if [ $os_family = debian ]; then
  # Ubuntu and Debian have different package names for libjpeg
  # Ubuntu and Debian versions have differnet package names for libpng-dev
  # Ubuntu 18.04 does not include universe repo by default
  source /etc/os-release
  if [[ "${NAME}" == "Ubuntu" ]]
  then
      JPEGTURBO="libjpeg-turbo8-dev"
      if [[ "${VERSION_ID}" == "18.04" ]]
      then
          sed -i 's/bionic main$/bionic main universe/' /etc/apt/sources.list
      fi
      if [[ "${VERSION_ID}" == "16.04" ]]
      then
          LIBPNG="libpng12-dev"
      else
          LIBPNG="libpng-dev"
      fi
  elif [[ "${NAME}" == *"Debian"* ]]
  then
      JPEGTURBO="libjpeg62-turbo-dev"
      if [[ "${PRETTY_NAME}" == *"stretch"* ]]
      then
          LIBPNG="libpng-dev"
      else
          LIBPNG="libpng12-dev"
      fi
  else
      echo "Unsupported Distro - Ubuntu or Debian Only"
      exit 1
  fi
  # install dependencies
  apt -y install build-essential libcairo2-dev ${JPEGTURBO} ${LIBPNG} libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev tomcat8 freerdp-x11 libjpeg-dev gcc-6
  export CC="gcc-6"
elif [ $os_family = fedora ]; then  
  # install dependencies
  yum -y install make gcc pam-devel wget cairo-devel libjpeg-turbo-devel libpng-devel uuid-devel
  # install optional dependencies
  # ffmpeg-devel (prereq)
  yum -y install epel-release
  rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
  rpm -Uvh http://li.nux.ro/download/nux/dextop/el$osversion_id/x86_64/nux-dextop-release-0-5.el$osversion_id.nux.noarch.rpm
  rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el$osversion_id.nux.noarch.rpm
  yum -y install ffmpeg-devel
  # more dependencies
  yum -y install freerdp-devel pango-devel libssh2-devel libtelnet-devel libvncserver-devel pulseaudio-libs-devel openssl-devel libvorbis-devel libwebp-devel tomcat
  # allow connections through selinux
  setsebool -P httpd_can_network_connect 1
  setsebool -P httpd_can_network_relay 1
  # enable and start tomcat
  systemctl enable tomcat
  systemctl start tomcat
else
  echo "unknown operating system family"
  exit 1
fi

# If dependencies fail, exit
if [ $? -ne 0 ]; then
    echo "failed to install all required dependencies"
    exit
fi

# find and set tomcat location
if [ -e /usr/share/tomcat/webapps ]; then
    TOMCAT_LOCATION=/usr/share/tomcat
    TOMCAT_SERVICE=tomcat
elif [ -e /var/lib/tomcat8/webapps ]; then
    TOMCAT_LOCATION=/var/lib/tomcat8
    TOMCAT_SERVICE=tomcat8
elif [ -e /var/lib/tomcat7/webapps ]; then
    TOMCAT_LOCATION=/var/lib/tomcat7
    TOMCAT_SERVICE=tomcat
elif [ -e /var/lib/tomcat/webapps ]; then
    TOMCAT_LOCATION=/var/lib/tomcat
    TOMCAT_SERVICE=tomcat
else
  echo "unable to find tomcat directory"
  exit 1
fi

# Download Guacamole server source code
wget http://archive.apache.org/dist/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download guacamole-server-${GUAC_VERSION}.tar.gz"
    echo "http://archive.apache.org/dist/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz"
    exit
fi

# Extract guac code and build
tar -xzf guacamole-server-${GUAC_VERSION}.tar.gz
cd guacamole-server-${GUAC_VERSION}
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig

#start guacd service
systemctl enable guacd
systemctl start guacd

# Download Guacamole client to tomcat location
wget -O ${TOMCAT_LOCATION}/webapps/guacamole.war http://archive.apache.org/dist/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war
if [ $? -ne 0 ]; then
    echo "Failed to guacamole-${GUAC_VERSION}.war"
    echo "http://archive.apache.org/dist/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war"
    exit
fi

# create required directory structure
mkdir -p /etc/guacamole/{extensions,lib}
# ln -s /etc/guacamole ${TOMCAT_LOCATION}/.guacamole

echo -e "Installation complete, point your browser to http://server:8080/guacamole
|        to access guacamole."
if [ $os_family = fedora ]; then
  echo "    be sure to open firewall ports, example:"
  # temporarily open firewall (don't forget to restrict)
  echo "    firewall-cmd --add-port=8080/tcp --permanent"
  echo "    firewall-cmd --reload"
fi
