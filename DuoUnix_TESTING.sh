#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --ikey INTEGRATION_KEY --skey SECRET_KEY --host API_HOSTNAME --auth "ssh or none" --version VERSION
# OR
# ./filename.sh -i INTEGRATION_KEY -s SECRET_KEY -h API_HOSTNAME -a "ssh or none"-v VERSION


# Version numbers
duo_version="1.11.0"

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
        -i | --ikey )
            shift
            duo_ikey="$1"
            ;;
        -s | --skey )
            shift
            duo_skey="$1"
            ;;
        -h | --host )
            shift
            duo_host="$1"
            ;;
        -a | --auth )
            shift
            duo_auth="$1"
            ;;
        -v | --version )
            shift
            duo_version="$1"
            ;;
    esac
    shift
done

if [ -z "$duo_ikey" ]; then
    echo
    read -p "Enter the Duo integration key: " duo_ikey
    echo
fi
if [ -z "$duo_skey" ]; then
    echo
    read -p "Enter the Duo secret key: " duo_skey
    echo
fi
if [ -z "$duo_host" ]; then
    echo
    read -p "Enter the Duo API hostname: " duo_host
    echo
fi
if [ -z "$duo_auth" ]; then
    echo
    read -p "Enter the Authentication type to protect (ssh, system-wide, or none): " duo_auth
    echo
fi

# install prereqs
if [ $os_family = debian ]; then
  apt-get -y install wget make gcc libpam-dev libssl-dev build-essential
elif [ $os_family = fedora ]; then  
  yum -y install make gcc pam-devel openssl-devel wget
else
  echo "unknown operating system family"
  exit 1
fi

# If prereqs fail, exit
if [ $? -ne 0 ]; then
    echo "failed to install all required dependencies"
    exit
fi

# Download Duo
wget https://dl.duosecurity.com/duo_unix-${duo_version}.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download duo_unix-${duo_version}.tar.gz"
    echo "https://dl.duosecurity.com/duo_unix-${duo_version}.tar.gz"
    exit
fi

# Extract Duo
tar -xzf duo_unix-${duo_version}.tar.gz

# Build and install Duo with PAM
cd duo_unix-${duo_version}
./configure --with-pam --prefix=/usr && make && sudo make install

# modify /etc/duo/pam_duo.conf with duo skey, ikey, and host... replacing lines
DUO_IKEY_REPLACETEXT='ikey ='
DUO_IKEY_NEW="ikey = $duo_ikey"
sed -i "/$DUO_IKEY_REPLACETEXT/c $DUO_IKEY_NEW" /etc/duo/pam_duo.conf

DUO_SKEY_REPLACETEXT='skey ='
DUO_SKEY_NEW="skey = $duo_skey"
sed -i "/$DUO_SKEY_REPLACETEXT/c $DUO_SKEY_NEW" /etc/duo/pam_duo.conf

DUO_HOST_REPLACETEXT='host ='
DUO_HOST_NEW="host = $duo_host"
sed -i "/$DUO_HOST_REPLACETEXT/c $DUO_HOST_NEW" /etc/duo/pam_duo.conf

# get and set pam_duo.so location for authentications
pam_duo_so_location=pam_duo.so
test -e /lib64/security/pam_duo.so && pam_duo_so_location=/lib64/security/pam_duo.so

# update authentications for duo if specified
if [ $os_family = debian ] && [ "$duo_auth" = ssh ]; then
sed -i "/^@include common-auth/c\\
#@include common-auth\\
auth  [success=1 default=ignore] $pam_duo_so_location\\
auth  requisite pam_deny.so\\
auth  required pam_permit.so\\
" /etc/pam.d/sshd
fi
if [ $os_family = fedora ] && [ "$duo_auth" = ssh ]; then  
sed -i "/^auth  substack password-auth/c\\
#auth  substack password-auth\\
auth  required pam_env.so\\
auth  sufficient $pam_duo_so_location\\
auth  required pam_deny.so\\
" /etc/pam.d/sshd
fi

#### system-wide not currently working####
#if [ $os_family = debian ] && [ "$duo_auth" = "system-wide" ]; then
#sed -i "/^auth  [success=1 default=ignore] pam_unix.so nullok_secure/c\\
# auth  [success=1 default=ignore] pam_unix.so nullok_secure\\
#auth  requisite pam_unix.so nullok_secure\\
#auth  [success=1 default=ignore] $pam_duo_so_location\\
#" /etc/pam.d/common-auth
#fi
#if [ $os_family = fedora ] && [ "$duo_auth" = "system-wide" ]; then
#sed -i "/^auth  sufficient pam_unix.so nullok try_first_pass/c\\
# auth  sufficient pam_unix.so nullok try_first_pass\\
#auth  requisite pam_unix.so nullok try_first_pass\\
#auth  sufficient $pam_duo_so_location\\
#" /etc/pam.d/system-auth
#fi

# add autopush to file
# run commands until line matches exactly as intended in file
until grep -qxF 'autopush = yes' /etc/duo/pam_duo.conf
do
    #remove any lines containing autopush
	sed -i '/autopush/d' /etc/duo/pam_duo.conf
    #add required line to file
	echo 'autopush = yes' >> /etc/duo/pam_duo.conf
done

echo -e "Installation complete, see https://duo.com/docs/duounix
|        for documentation."
# temporarily open firewall for fedora
if [ $os_family = fedora ]; then
  echo "be sure to open firewall ports, example:"
  # temporarily open firewall (don't forget to restrict)
  echo "firewall-cmd --permanent --add-port=3000/tcp"
  echo "firewall-cmd --reload"
fi
