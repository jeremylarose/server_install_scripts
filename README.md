## Check_MK Raw Edition (Debian, Ubuntu, CentOS, RHEL)

version: 1.5.0p11

* installs or updates Check_MK Raw, creates and starts a site if doesn't exist
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Check_MK_Raw.sh && chmod +x Check_MK_Raw.sh && ./Check_MK_Raw.sh -v '1.5.0p11' -s monitoring && rm -f Check_MK_Raw.sh

## Elastic Stack / ELK (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 6.5.4

* Installs Oracle Java JRE, Elasticsearch, Logstash, and Kibana and tunes Elasticsearch as recommended with heap size
* use no more than half of your system memory for heap size and max of 32gb
* script doesn't cover it, but don't forget to set correct # of shards and replicas for Elasticsearch
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticStack.sh && chmod +x ElasticStack.sh && ./ElasticStack.sh -v "6.5.4" -h 4g && rm -f ElasticStack.sh


## Gitea (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.6.4

* builds with PAM authentication capability (not available with developer binaries) and Installs with service (mysql) enabled
* usage example (install Gitea and MariaDB with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Gitea.sh && chmod +x Gitea.sh && ./Gitea.sh && rm -f Gitea.sh

## Guacamole, Apache (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 1.0.0

* Installs or upgrades Apache Guacamole, installs any extensions specified in command line, adds JDBC Drivers for mysql and postgresql if needed, also copies database schema to /etc/guacamole for easy access for upgrade
* usage example (install Guacamole and MariaDB with two commands filling in your command line arguments):
1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh
2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Guacamole.sh && chmod +x Guacamole.sh && ./Guacamole.sh -v 1.0.0 -e auth-cas -e auth-jdbc -a mysql && rm -f Guacamole.sh
3. modify /etc/guacamole/guacamole.properties and update schema if needed

  - current extension options (-e): auth-cas, auth-duo, auth-header, auth-jdbc, auth-ldap, auth-noauth, auth-openid
  - current db authentication options (-a): mysql, postgresql

## MariaDB (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: 10.3

* Installs MariaDB and/or just creates a database if mariadb/mysql already installed
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB.sh

## OCS Inventory NG (Debian, Ubuntu, CentOS, RHEL)

version: 2.5

* install example (install OCS Inventory NG and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB.sh && chmod +x MariaDB.sh && ./MariaDB.sh -r 'rootpassword' -d ocsweb -u ocs_dbuser -p 'dbpassword' && rm -f MariaDB.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/OCSInventoryNG.sh && chmod +x OCSInventoryNG.sh && ./OCSInventoryNG.sh -u ocs_dbuser -p 'dpbassword' -v 2.5 -h localhost -p 3306 && rm -f OCSInventoryNG.sh

## SaltGUI (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: SaltGUI 1.8.0

* installs or updates SaltGUI
* install example (SaltGUI and Salt-Master with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v 2018.3 -c salt-api -c salt-minion && rm -f SaltMaster.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltGUI.sh && chmod +x SaltGUI.sh && ./SaltGUI.sh -u saltguiadminuser -p 'saltguiadminuserpassword' -v 1.8.0 && rm -f SaltGUI.sh

## SaltMaster, saltstack (Debian, Ubuntu, CentOS, RHEL)

version: 2018.3

* installs or updates salt-master and any other specified components
* usage example:
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/SaltMaster.sh && chmod +x SaltMaster.sh && ./SaltMaster.sh -v '2018.3' -c salt-api -c salt-minion && rm -f SaltMaster.sh

- current component options (-c): salt-minion, salt-ssh, salt-syndic, salt-cloud, salt-api

## Wazuh (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: Wazuh 3.8.1, ElasticStack 6.5.4

* installs or upgrades Wazuh
* install example (Wazuh and Elastic Stack (ELK) with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticStack.sh && chmod +x ElasticStack.sh && ./ElasticStack.sh -v 6.5.4 -h 4g && rm -f ElasticStack.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Wazuh.sh && chmod +x Wazuh.sh && ./Wazuh.sh -v 3.8.1 -e 6.5.4 -l local && rm -f Wazuh.sh
