## Check_MK

version: 1.5.0p3


* install example (Install Check_MK for CentOS or RHEL with one line command):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Check_MK_CentOS-RHEL.sh && chmod +x Check_MK_CentOS-RHEL.sh && ./Check_MK_CentOS-RHEL.sh -v '1.5.0p3' -c el7 -s monitoring && rm -f Check_MK_CentOS-RHEL.sh


## MariaDB

version: 10.3

* install example (Install MariaDB and create database in Ubuntu):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB_Ubuntu.sh && chmod +x MariaDB_Ubuntu.sh && ./MariaDB_Ubuntu.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB_Ubuntu.sh

## Gitea

version: 1.5.0

* builds with PAM authentication capability (not available with developer binaries)
* install example (install Gitea and MariaDB with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB_Ubuntu.sh && chmod +x MariaDB_Ubuntu.sh && ./MariaDB_Ubuntu.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB_Ubuntu.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Gitea_PAM_Ubuntu.sh && chmod +x Gitea_PAM_Ubuntu.sh && ./Gitea_PAM_Ubuntu.sh && rm -f Gitea_PAM_Ubuntu.sh

## OCS Inventory NG

version: 2.5

* install example (install OCS Inventory NG and MariaDB with two commands filling in your command line arguments):

  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB_Ubuntu.sh && chmod +x MariaDB_Ubuntu.sh && ./MariaDB_Ubuntu.sh -r 'rootpassword' -d ocsweb -u ocs_dbuser -p 'dbpassword' && rm -f MariaDB_Ubuntu.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/OCSInventoryNG_Ubuntu.sh && chmod +x OCSInventoryNG_Ubuntu.sh && ./OCSInventoryNG_Ubuntu.sh -u ocs_dbuser -p 'dpbassword' -v 2.5 -h localhost -p 3306 && rm -f OCSInventoryNG_Ubuntu.sh
