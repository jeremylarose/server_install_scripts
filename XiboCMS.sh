#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version xibo_version --composeversion docker-compose_version
# OR
# ./filename.sh -v version -cv compose-version

# default variables unless specified from command line
XIBO_VERSION="2.3.6"
DOCKERCOMPOSE_VERSION="1.26.2"


# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            XIBO_VERSION="$1"
            ;;
        -cv | --composeversion )
            shift
            DOCKERCOMPOSE_VERSION="$1"
            ;;
    esac
    shift
done

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
  mv xibo "xibo_backup_$now"
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

# copy config file if not exist
  if [[ ! -f /opt/xibo/config.env ]]; then
  cp /opt/xibo/config.env.template /opt/xibo/config.env
  fi

# Bring CMS up with Docker Compose
cd /opt/xibo
docker-compose up -d

echo "Xibo CMS $XIBO_VERSION setup/upgrade complete https://xibo.org.uk/docs/setup/cms-installation-guides"
