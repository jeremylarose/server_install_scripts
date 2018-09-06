## Check_MK

version: 1.5.0p3

## MariaDB

version: 10.3

* wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/MariaDB_Ubuntu.sh && chmod +x MariaDB_Ubuntu.sh && ./MariaDB_Ubuntu.sh -r password -d databasename -u dbusername -p dbpassword && rm -f MariaDB_Ubuntu.sh

## Gitea

version: 1.5.0
* builds with PAM authentication capability (not available with developer binaries)
* wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Gitea_PAM_Ubuntu.sh && chmod +x Gitea_PAM_Ubuntu.sh && ./Gitea_PAM_Ubuntu.sh && rm -f Gitea_PAM_Ubuntu.sh

## OCS Inventory NG

version: 2.5
