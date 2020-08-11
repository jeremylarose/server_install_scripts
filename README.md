## Check_MK Raw Edition (Debian, Ubuntu, CentOS, RHEL)

version: 1.6.0p13

* installs or updates Check_MK Raw, creates and starts a site if doesn't exist
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Check_MK_Raw.sh && chmod +x Check_MK_Raw.sh && ./Check_MK_Raw.sh -v '1.6.0p13' -s monitoring && rm -f Check_MK_Raw.sh

## Cronicle (Debian, Ubuntu, CentOS, RHEL)

version: 0.8.45

* installs or updates Cronicle as master or slave, and sets variables if specified
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Cronicle.sh && chmod +x Cronicle.sh && ./Cronicle.sh -r master -h myhost.somewhere.com -s mysecretserverkey && rm -f Cronicle.sh

## Docker (Debian, Ubuntu)

version: 5:19.03.6~3-0

* installs or updates Docker
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Docker.sh && chmod +x Docker.sh && ./Docker.sh -v "5:19.03.6~3-0" && rm -f Docker.sh

## Elastic Stack / ELK (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 7.6.2

* Installs Oracle Java JRE, Elasticsearch, Logstash, and Kibana and tunes Elasticsearch as recommended with heap size
* use no more than half of your system memory for heap size and max of 32gb
* script doesn't cover it, but don't forget to set correct # of shards and replicas for Elasticsearch
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticStack.sh && chmod +x ElasticStack.sh && ./ElasticStack.sh -v "7.6.2" -h 4g && rm -f ElasticStack.sh


## Gitea (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.11.5, Go 1.14.2

* builds with PAM authentication capability (not available with developer binaries) and Installs with service (mysql) enabled
* usage example (install Gitea and MariaDB with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Gitea.sh && chmod +x Gitea.sh && ./Gitea.sh && rm -f Gitea.sh

## Guacamole, Apache (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.1.0

* Installs or upgrades Apache Guacamole, installs any extensions specified in command line, adds JDBC Drivers for mysql and postgresql if needed, also copies database schema to /etc/guacamole for easy access for upgrade
* usage example (install Guacamole and MariaDB with two commands filling in your command line arguments):
1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Guacamole.sh && chmod +x Guacamole.sh && ./Guacamole.sh -v 1.1.0 -e auth-cas -e auth-jdbc -a mysql && rm -f Guacamole.sh
3. modify /etc/guacamole/guacamole.properties and update schema if needed

  - current extension options (-e): auth-cas, auth-duo, auth-header, auth-jdbc, auth-ldap, auth-noauth, auth-openid
  - current db authentication options (-a): mysql, postgresql

## MariaDB (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 10.3

* Installs MariaDB and/or just creates a database if mariadb/mysql already installed
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh

## MeshCentral, MongoDB (Debian, Ubuntu, CentOS, RHEL)

version: 0.6.2, MongoDB 4.2

* installs or updates a MeshCentral Server, conifgures for MongoDB, and starts meshcentral as systemd service
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MeshCentral.sh && chmod +x MeshCentral.sh && ./MeshCentral.sh -v "0.6.2" && rm -f MeshCentral.sh

## Munkireport (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: munkireport-php 5.4.1, PHP 7.3

* install example (install Munkireport and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d munkireport -u munki_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Munkireport.sh && chmod +x Munkireport.sh && ./Munkireport.sh -d mysql -u munki_dbuser -p 'dbpassword' -v 5.4.1 -h 127.0.0.1 -n 3306 && rm -f Munkireport.sh

## OCS Inventory NG (Debian, Ubuntu, CentOS, RHEL)

version: 2.7, PHP 7.3

* install example (install OCS Inventory NG and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d ocsweb -u ocs_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/OCSInventoryNG.sh && chmod +x OCSInventoryNG.sh && ./OCSInventoryNG.sh -u ocs_dbuser -p 'dbpassword' -v 2.7 -h localhost -n 3306 && rm -f OCSInventoryNG.sh

## SaltGUI (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: SaltGUI 1.21.0

* installs or updates SaltGUI
* install example (SaltGUI and Salt-Master with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v latest -c salt-api -c salt-minion && rm -f SaltMaster.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltGUI.sh && chmod +x SaltGUI.sh && ./SaltGUI.sh -u saltguiadminuser -p 'saltguiadminuserpassword' -v 1.21.0 && rm -f SaltGUI.sh

## SaltMaster, saltstack (Debian, Ubuntu, CentOS, RHEL)

version: 3000, Py3

* installs or updates salt-master and any other specified components
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v 'latest' -c salt-api -c salt-minion && rm -f SaltMaster.sh

- current component options (-c): salt-minion, salt-ssh, salt-syndic, salt-cloud, salt-api

## SimpleHelp (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 5.2.3

* NOTE: this is not open source software, see licensing here ( https://simple-help.com/pricing )
* installs or updates SimpleHelp Server
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SimpleHelp.sh && chmod +x SimpleHelp.sh && ./SimpleHelp.sh -s systemd && rm -f SimpleHelp.sh

## Wazuh (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: Wazuh 3.12.2, ElasticStack 7.6.2

* installs or upgrades Wazuh
* install example (Wazuh and Elastic Stack (ELK) with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticStack.sh && chmod +x ElasticStack.sh && ./ElasticStack.sh -v 7.6.2 -h 8g && rm -f ElasticStack.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Wazuh.sh && chmod +x Wazuh.sh && ./Wazuh.sh -v 3.12.2 -e 7.6.2 -l localhost && rm -f Wazuh.sh
