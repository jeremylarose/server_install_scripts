#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version xibo_version --composeversion docker-compose_version --dbpwd password --xmrport xmrport --webport cmswebport
# OR
# ./filename.sh -v version -cv compose-version -p password -xp xmrport -wp webport

# default variables unless specified from command line
XIBO_VERSION="2.3.6"
DOCKERCOMPOSE_VERSION="1.26.2"
xiboxmrport="65500"
xibowebport="65501"

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -p | --dbpwd )
            shift
            xibodbpwd="$1"
            ;;
        -v | --version )
            shift
            XIBO_VERSION="$1"
            ;;
        -cv | --composeversion )
            shift
            DOCKERCOMPOSE_VERSION="$1"
            ;;
        -xp| --xmrport )
            shift
            xiboxmrport="$1"
            ;;
        -wp| --webport )
            shift
            xibowebport="$1"
            ;;
    esac
    shift
done

if [ -z "$xibodbpwd" ]; then
    echo
    while true
    do
        read -s -p "Enter the Xibo CMS User Database Password for cms: " xibodbpwd
        echo
        read -s -p "Confirm the Xibo CMS User Database Password for cms: " password2
        echo
        [ "$xibodbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi

# install Docker Compose (Docker should already be installed)
curl -L https://github.com/docker/compose/releases/download/${DOCKERCOMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    echo "Failed to download docker-compose ${DOCKERCOMPOSE_VERSION}"
fi

# backup current version if installed
now=$(date +"%Y%m%d_%H%M%S")
if [ -d "/opt/xibo" ]; then
  cd /opt/xibo
  docker-compose stop
  cd ..
  echo "Backing up the Xibo installation to xibo_backup_$now"
  cp -rp xibo "xibo_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# install or upgrade Xibo CMS
mkdir /opt/xibo
cd /opt/xibo
wget https://github.com/xibosignage/xibo-cms/releases/download/${XIBO_VERSION}/xibo-docker.tar.gz
tar --strip-components=1 -zxvf xibo-docker.tar.gz
rm xibo-docker.tar.gz

if [ $? -ne 0 ]; then
    echo "Failed to download Xibo CMS ${XIBO_VERSION}"
fi

# copy config file if not exist and set mysql password
if [[ ! -f /opt/xibo/config.env ]]; then
cp /opt/xibo/config.env.template /opt/xibo/config.env
XIBO_MYSQLPW_REPLACETEXT='MYSQL_PASSWORD='
XIBO_MYSQLPW_NEW='MYSQL_PASSWORD=zreplaceholder'
sed -i "/$XIBO_MYSQLPW_REPLACETEXT/c $XIBO_MYSQLPW_NEW" /opt/xibo/config.env
sed -i "s/zreplaceholder/$xibodbpwd/" /opt/xibo/config.env
fi

# Bring CMS up with Docker Compose and specified ports
if [[ ! -f /opt/xibo/cms_custom-ports.yml ]]; then
cp /opt/xibo/cms_custom-ports.yml.template /opt/xibo/cms_custom-ports.yml
XIBO_XMRPORT_REPLACETEXT='65500:9505'
XIBO_XMRPORT_NEW="$xiboxmrport:9505"
sed -i "s/$XIBO_XMRPORT_REPLACETEXT/$XIBO_XMRPORT_NEW/g" /opt/xibo/cms_custom-ports.yml
XIBO_WEBPORT_REPLACETEXT='65501:80'
XIBO_WEBPORT_NEW="$xibowebport:80"
sed -i "s/$XIBO_WEBPORT_REPLACETEXT/$XIBO_WEBPORT_NEW/g" /opt/xibo/cms_custom-ports.yml
fi

cd /opt/xibo
docker-compose -f cms_custom-ports.yml up -d

echo "Xibo CMS $XIBO_VERSION setup/upgrade complete https://xibo.org.uk/docs/setup/cms-installation-guides"
echo "http://yourserverhere:$xibowebport"
echo "default username is xibo_admin, default password is password"
