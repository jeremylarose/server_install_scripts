#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
# or automated with ./filename.sh --version munkireport_version --location '/usr/local/munkireport' --database "mysql or sqlite" --mysqluser username --mysqlpwd password --mysqlhost hostname --mysqlport portnumber
# OR
# ./filename.sh -v version -l location -d "mysql or sqlite" -u mysqlusername -p mysqlpassword -h mysqlhostname -n mysqlhostportnumber

# default variables unless specified from command line
MUNKIREPORT_VERSION="4.0.2"
MUNKIREPORT_LOCATION="/usr/local/munkireport"
DATABASE="sqlite"
MYSQL_HOST="127.0.0.1"
MYSQL_HOSTPORT="3306"

PARENTDIR="$(dirname "$MUNKIREPORT_LOCATION")"

# get os from system
os=`cat /etc/*release | grep ^ID= | cut -d= -f2 | sed 's/\"//g'`

# get os family from system
if [ $os = debian ] || [ $os = fedora ]; then
  os_family=$os
else
  os_family=`cat /etc/*release | grep ^ID_LIKE= | cut -d= -f2 | sed 's/\"//g' | cut -d' ' -f2`
fi

# get os version id from system
osversion_id=`cat /etc/*release | grep ^VERSION_ID= | cut -d= -f2 | sed 's/\"//g' | cut -d. -f1`

# Get script arguments for non-interactive mode
while [ "$1" != "" ]; do
    case $1 in
        -v | --version )
            shift
            MUNKIREPORT_VERSION="$1"
            ;;
        -l | --location )
            shift
            MUNKIREPORT_LOCATION="$1"
            ;;
        -d | --database )
            shift
            DATABASE="$1"
            ;;
        -u | --mysqluser )
            shift
            MYSQL_USER="$1"
            ;;
        -p | --mysqlpwd )
            shift
            MYSQL_PWD="$1"
            ;;
        -h | --mysqlhost )
            shift
            MYSQL_HOST="$1"
            ;;
        -n | --mysqlport )
            shift
            MYSQL_HOSTPORT="$1"
            ;;
    esac
    shift
done

if [ $DATABASE = mysql ] && [ -z "$MYSQL_USER" ]; then
    echo
    read -p "Enter the Munkireport database username with access: " MYSQL_DBUSER
    echo
fi
if [ $DATABASE = mysql ] && [ -z "$MYSQL_PWD" ]; then
    echo
    while true
    do
        read -s -p "Enter the Munkireport User Database Password: " MYSQL_DBPWD
        echo
        read -s -p "Confirm the Munkireport User Database Password: " password2
        echo
        [ "$ocsdbpwd" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
fi


# install prereqs
if [ $os_family = debian ]; then
  apt-get -y install wget php7.3-mysql php7.3-fpm php7.3-xml
elif [ $os_family = fedora ]; then
  # install prerequisites
  yum -y install epel-release wget
  # add Remi repo for php 7.3
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-${osversion_id}.rpm
  # install php 7.3 from repo
  yum --enablerepo=remi-php73 install php php-pdo php-xml
else
  echo "unknown operating system family"
  exit 1
fi

# If fails to exit
if [ $? -ne 0 ]; then
     echo "failed to install all required dependencies"
     exit
fi

# Generate a timestamp
now=$(date +"%Y%m%d_%H%M%S")

# backup current installation if exists
if [ -d ${MUNKIREPORT_LOCATION} ]; then
  cd ${MUNKIREPORT_LOCATION}
  cd ..

  echo "Backing up the munkireport installation to munkireport_backup_$now"
  mv munkireport "munkireport_backup_$now"
  # exit on backup fail
  if [ $? -ne 0 ]; then
    echo "failed to backup properly, exiting"
    exit
  fi
fi

# Fetch the new version
echo "Downloading the latest version"
    wget https://github.com/munkireport/munkireport-php/releases/download/v${MUNKIREPORT_VERSION}/munkireport-php-v${MUNKIREPORT_VERSION}.tar.gz
    mkdir -p ${MUNKIREPORT_LOCATION}
    tar -xzf munkireport-php-v${MUNKIREPORT_VERSION}.tar.gz -C ${MUNKIREPORT_LOCATION} --strip-components=1

# put in maintenance mode
touch ${MUNKIREPORT_LOCATION}/storage/framework/down

# set .env file file
if [ $DATABASE = sqlite ]; then
# add MariaDB repo for centos
cat <<EOF >${MUNKIREPORT_LOCATION}/.env
# --------------------------------------------------------------
# munkireport-php phpdotenv configuration file.
#
# Module specific variables should contain the module prefix.
# --------------------------------------------------------------

# DATABASE
# --------
CONNECTION_DRIVER="sqlite"
CONNECTION_DATABASE="app/db/db.sqlite"
EOF
elif [ $DATABASE = mysql ]; then
cat <<EOF >${MUNKIREPORT_LOCATION}/.env
# --------------------------------------------------------------
# munkireport-php phpdotenv configuration file.
#
# Module specific variables should contain the module prefix.
# --------------------------------------------------------------

# DATABASE
# --------

CONNECTION_DRIVER="mysql"
CONNECTION_HOST="${MYSQL_HOST}"
CONNECTION_PORT="${MYSQL_HOSTPORT}"
CONNECTION_DATABASE="munkireport"
CONNECTION_USERNAME="${MYSQL_DBUSER}"
CONNECTION_PASSWORD="${MYSQL_DBPWD}"
CONNECTION_CHARSET="utf8mb4"
CONNECTION_COLLATION="utf8mb4_unicode_ci"
CONNECTION_STRICT=TRUE
CONNECTION_ENGINE="InnoDB"
EOF
FI

# add rest of example .env
cat <<EOF >>${MUNKIREPORT_LOCATION}/.env
# INDEX_PAGE
# ----------
# Default is index.php? which is the most compatible form.
# You can leave it blank if you want nicer looking urls.
# You will need a server which honors .htaccess (apache) or
# figure out how to rewrite urls in the server of your choice.

INDEX_PAGE="index.php?"

# URI_PROTOCOL
# ------------
# $_SERVER variable that contains the correct request path,
# e.g. 'REQUEST_URI', 'QUERY_STRING', 'PATH_INFO', etc.
# defaults to AUTO

URI_PROTOCOL="AUTO"

# WEBHOST
# -------
# The hostname of the webserver, default automatically
# determined. no trailing slash

#WEBHOST="https://munkireport"

# SUBDIRECTORY
# ------------
# Relative to the webroot, with trailing slash.
# If you're running munkireport from a subdirectory of a website,
# enter subdir path here. E.g. if munkireport is accessible here:
# http://mysite/munkireport/ you should set subdirectory to
# '/munkireport/'
# If you're using .htaccess to rewrite urls, you should change that too
# The code below is for automagically determining your subdirectory,
# if it fails, just add $conf['subdirectory'] = '/your_sub_dir/' in
# config.php

#SUBDIRECTORY="/munkireport/"

# SITENAME
# --------
# Will appear in the title bar of your browser and as heading on each webpage
#

SITENAME="MunkiReport"

# Hide Non-active Modules
#
# When false, all modules will be shown in the interface like
#	in the 'Listings' menu.
#HIDE_INACTIVE_MODULES=TRUE




# AUTHENTICATION
# --------------
#
# AUTH_METHODS can be one of
# - "NOAUTH": No authentication
# - "LOCAL" : Local Users defined as .yml in the "users" folder
# - "LDAP": LDAP Authentication
# - "AD": Active Directory Authentication
# - Any combination of the above, comma separated.
#
# Authentication providers are checked in this order:
# - Noauth
# - Generated local user
# - LDAP
# - Active Directory


AUTH_METHODS="NOAUTH"

# LDAP AUTHENTICATION
# -------------------
# The LDAP server hostname or IP address
AUTH_LDAP_SERVER="ldap.server.local"
#AUTH_LDAP_PORT=389
#AUTH_LDAP_VERSION=3
#AUTH_LDAP_USE_STARTTLS=FALSE
#AUTH_LDAP_FOLLOW_REFERRALS=FALSE
#AUTH_LDAP_BIND_DN=""
#AUTH_LDAP_BIND_PASSWORD=""
#AUTH_LDAP_DEREF=0

# Use Debugging
#AUTH_LDAP_DEBUG=FALSE


# The search base for user objects (formerly usertree)
AUTH_LDAP_USER_BASE="cn=users,dc=server,dc=local"
# The LDAP filter to use for user objects
#AUTH_LDAP_USER_FILTER="(&(uid=%{user})(objectClass=posixAccount))"
#AUTH_LDAP_USER_SCOPE="sub"


# The search base for group objects
AUTH_LDAP_GROUP_BASE="cn=groups,dc=server,dc=local"
# The LDAP filter to use for group objects
#AUTH_LDAP_GROUP_FILTER="(&(objectClass=posixGroup)(memberUID=%{uid}))"
#AUTH_LDAP_GROUP_SCOPE="sub"
#AUTH_LDAP_GROUP_KEY="cn"

# LDAP Users and Groups that are allowed to access MunkiReport
AUTH_LDAP_ALLOWED_USERS="user1,user2"
AUTH_LDAP_ALLOWED_GROUPS="group1,group2"

# ACTIVE DIRECTORY AUTHENTICATION
# -------------------------------
#
AUTH_AD_ACCOUNT_SUFFIX="@mydomain.local"
AUTH_AD_BASE_DN="dc=mydomain,dc=local"
AUTH_AD_HOSTS="dc01.mydomain.local,dc02.mydomain.local"
AUTH_AD_ALLOWED_USERS="user1,user2"
AUTH_AD_ALLOWED_GROUPS="group1,group2"
AUTH_AD_RECURSIVE_GROUPSEARCH=FALSE

# RECAPTCHA
# ---------
# Enable reCaptcha Support on the Authentication Form
# Request API keys from https://www.google.com/recaptcha
#
RECAPTCHA_LOGIN_PUBLIC_KEY=""
RECAPTCHA_LOGIN_PRIVATE_KEY=""

# ROLES
# -----
# Add users or groups to the appropriate roles array.
#
#ROLES_ADMIN="*"

# LOCAL GROUPS
# ------------
# Create local groups, add users to groups.
#
#GROUPS_ADMIN_USERS="user1,user2"

# Set to TRUE to enable Business Units
# For more information, see docs/business_units.md
ENABLE_BUSINESS_UNITS=TRUE

# Force secure connection when authenticating
#
# Set this value to TRUE to force https when logging in.
# This is useful for sites that serve MR both via http and https
AUTH_SECURE=TRUE

# If you want to have link that opens a screensharing or SSH
# connection to a client, enable these settings. If you don't
# want the links, set either to an empty string, eg:
# $conf['vnc_link'] = "";
VNC_LINK="vnc://%s:5900"
SSH_LINK="ssh://adminuser@%s"

# Define path to the curl binary and add options
# this is used by the installer script.
# Override to use custom path and add or remove options, some environments
# may need to add "--insecure" if the servercertificate is not to be
# checked.
CURL_CMD="/usr/bin/curl, --fail, --silent, --show-error"
EOF

# Copy across the old configuration files overwiting new
if [ -d "${PARENTDIR}/munkireport_backup_$now" ]; then
  echo "Copying across previous configuration files"
  cd ${PARENTDIR}/munkireport_backup_$now
  cp -f {config.php,.env,composer.local.json} ${MUNKIREPORT_LOCATION}
fi

# run migrations
cd ${MUNKIREPORT_LOCATION}
php database/migrate.php

# turn off maintenance mode
rm ${MUNKIREPORT_LOCATION}/storage/framework/down
