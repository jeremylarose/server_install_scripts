## Wazuh (Debian, Ubuntu, CentOS, RHEL, Fedora)

version: Wazuh 3.13.2, ElasticStack 7.9.1

* installs or upgrades Wazuh
* install example (Wazuh and Elastic Stack (ELK) with two commands filling in your command line arguments):
  1. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/ElasticStack.sh && chmod +x ElasticStack.sh && ./ElasticStack.sh -v 7.9.1 -h 8g && rm -f ElasticStack.sh
  2. wget https://raw.githubusercontent.com/jeremylarose/server_install_scripts/master/Wazuh.sh && chmod +x Wazuh.sh && ./Wazuh.sh -v 3.13.2 -e 7.9.1 -l localhost && rm -f Wazuh.sh
