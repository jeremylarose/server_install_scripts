## Check_MK Raw Edition (Debian, Ubuntu, CentOS, RHEL)

version: 2.2.0p28

* installs or updates Check_MK Raw, creates and starts a site if doesn't exist
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Check_MK_Raw.sh && chmod +x Check_MK_Raw.sh && ./Check_MK_Raw.sh -v '2.2.0p28' -s monitoring && rm -f Check_MK_Raw.sh

## Cronicle (Debian, Ubuntu, CentOS, RHEL)

version: 0.8.50

* installs or updates Cronicle as master or slave, and sets variables if specified
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Cronicle.sh && chmod +x Cronicle.sh && ./Cronicle.sh -r master -h myhost.somewhere.com -s mysecretserverkey && rm -f Cronicle.sh

## Docker (Debian, Ubuntu)

version: 5:19.03.12~3-0

* installs or updates Docker
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Docker.sh && chmod +x Docker.sh && ./Docker.sh -v "5:19.03.12~3-0" && rm -f Docker.sh

## DuoUnix (Debian, Ubuntu, CentOS, RHEL)

version: 1.12.0

* installs or updates Duo for Unix
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/DuoUnix.sh && chmod +x DuoUnix.sh && ./DuoUnix.sh -i INTEGRATION_KEY -s SECRET_KEY -h API_HOSTNAME -a ssh -v VERSION && rm -f DuoUnix.sh

## ElasticRepo (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 8.4.2

* Adds repo for Elasticsearch
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticRepo.sh && chmod +x ElasticRepo.sh && ./ElasticRepo.sh -v "8.4.2" && rm -f ElasticRepo.sh


## Gitea (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.23.4
* installs Gitea from binary with service (mysql) enabled
* usage example (install Gitea and MariaDB with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Gitea.sh && chmod +x Gitea.sh && ./Gitea.sh && rm -f Gitea.sh

## Guacamole, Apache (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.5.4

* Installs or upgrades Apache Guacamole, installs any extensions specified in command line, adds JDBC Drivers for mysql and postgresql if needed, also copies database schema to /etc/guacamole for easy access for upgrade
* usage example (install Guacamole and MariaDB with two commands filling in your command line arguments):
1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Guacamole.sh && chmod +x Guacamole.sh && ./Guacamole.sh -v 1.5.4 -e auth-sso-cas -e auth-jdbc -a mysql && rm -f Guacamole.sh
3. modify /etc/guacamole/guacamole.properties and update schema if needed

  - current extension options (-e): auth-duo, auth-header, auth-jdbc, auth-json, auth-ldap, *auth-noauth, auth-quickconnect, auth-sso-cas, auth-sso-openid, auth-sso-saml, auth-totp
  - current db authentication options (-a): mysql, postgresql

## MariaDB (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 11.4

* Installs MariaDB and/or just creates a database if mariadb/mysql already installed
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh

## MeshCentral, MongoDB (Debian, Ubuntu)

version: 1.1.44, MongoDB 7.0, Node.js 20

* installs or updates a MeshCentral Server, installs node.js, installs mongodb if not installed already, conifgures for MongoDB, and starts meshcentral as systemd service
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MeshCentral.sh && chmod +x MeshCentral.sh && ./MeshCentral.sh -v "1.1.44" && rm -f MeshCentral.sh

## Munkireport (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: munkireport-php 5.8.0, PHP 8.3

* install example (install Munkireport and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d munkireport -u munki_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Munkireport.sh && chmod +x Munkireport.sh && ./Munkireport.sh -d mysql -u munki_dbuser -p 'dbpassword' -v 5.8.0 -h 127.0.0.1 -n 3306 && rm -f Munkireport.sh

## OCS Inventory NG (Ubuntu, CentOS, RHEL)

version: 2.11.0, PHP 8.2

* install example (install OCS Inventory NG and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d ocsweb -u ocs_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/OCSInventoryNG.sh && chmod +x OCSInventoryNG.sh && ./OCSInventoryNG.sh -u ocs_dbuser -p 'dbpassword' -v 2.11.0 -h localhost -n 3306 && rm -f OCSInventoryNG.sh

## SaltGUI (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: SaltGUI 1.30.0

* installs or updates SaltGUI
* install example (SaltGUI and Salt-Master with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v latest -c salt-api -c salt-minion && rm -f SaltMaster.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltGUI.sh && chmod +x SaltGUI.sh && ./SaltGUI.sh -v 1.30.0 && rm -f SaltGUI.sh

## SaltMaster, saltstack (Debian, Ubuntu, CentOS, RHEL)

version: 3002, Py3

* installs or updates salt-master and any other specified components
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v 'latest' -c salt-api -c salt-minion && rm -f SaltMaster.sh

- current component options (-c): salt-minion, salt-ssh, salt-syndic, salt-cloud, salt-api

## SimpleHelp (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 5.5.8

* NOTE: this is not open source software, see licensing here ( https://simple-help.com/pricing )
* installs or updates SimpleHelp Server
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SimpleHelp.sh && chmod +x SimpleHelp.sh && ./SimpleHelp.sh -s systemd && rm -f SimpleHelp.sh

## Snipe-IT (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: snipe-it 8.1.1, PHP 8.3

* install example (install Snipe-IT and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d snipeit_db -u snipeit_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Snipe-IT.sh && chmod +x Snipe-IT.sh && ./Snipe-IT.sh -d snipeit_db -u snipeit_dbuser -p 'dbpassword' -v 8.1.1 -h 127.0.0.1 -n 3306 && rm -f Snipe-IT.sh

## WordPress (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: WordPress 6.8.1, PHP 8.4

* install example (install WordPress and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d wordpress -u wordpress_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/WordPress.sh && chmod +x WordPress.sh && ./WordPress.sh -l '/usr/local/wordpress' -u wordpress_dbuser -p 'dbpassword' -v 6.8.1 -h 127.0.0.1 -n 3306 && rm -f Munkireport.sh

## Xibo CMS using Docker (Debian, Ubuntu)

version: xibo-cms: 2.3.7, docker-compose: 1.26.2

* installs or upgrades Xibo CMS
* install example (Docker and Xibo CMS with default docker-compose version):
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Docker.sh && chmod +x Docker.sh && ./Docker.sh && rm -f Docker.sh
  3. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/XiboCMS.sh && chmod +x XiboCMS.sh && ./XiboCMS.sh -v 2.3.7 -p 'dbpassword' -wp 8080 -xp 65500
