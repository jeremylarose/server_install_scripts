ocs_server_packages:
  pkg.installed:
    - pkgs:
      - php-curl
      - apache2-dev
      - gcc
      - perl-modules-5.22
      - make
      - apache2
      - php
      - perl
      - libapache2-mod-perl2
      - libapache2-mod-php
      - libio-compress-perl
      - libxml-simple-perl
      - libdbi-perl
      - libdbd-mysql-perl
      - libapache-dbi-perl
      - libsoap-lite-perl
      - libnet-ip-perl
      - php-mysql
      - php-gd
      - php7.0-dev
      - php-mbstring
      - php-soap
      - php-xml
      - php-pclzip
      - libarchive-zip-perl
      - php7.0-zip
      - cpanminus

'cpanm Apache2::SOAP':
  cmd.run

'cpanm XML::Entities':
  cmd.run

'cpanm Net::IP':
  cmd.run

'cpanm Apache::DBI':
  cmd.run

'cpanm Mojolicious::Lite':
  cmd.run

'cpanm Switch':
  cmd.run

'cpanm Plack::Handler':
  cmd.run

ocs_mysql_setup:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password': {'type': 'string', 'value': '{{ pillar['ocs_mysql_root'] }}'}
        'mysql-server/root_password_again': {'type': 'string', 'value': '{{ pillar['ocs_mysql_root'] }}'}

mysql-server:
  pkg:
    - installed
    - require:
      - debconf: ocs_mysql_setup

ocsweb:
  mysql_database.present:
    - character_set: utf8
    - collate: utf8_bin
    - connection_user: root
    - connection_pass: {{ pillar['ocs_mysql_root'] }}

db_ocs_remove:
  mysql_user.absent:
    - name: ocs
    - host: localhost
    - connection_user: root
    - connection_pass: {{ pillar['ocs_mysql_root'] }}
    - connection_db: ocsweb

ocs_dbuser:
  mysql_user.present:
    - host: localhost
    - password: {{ pillar['ocs_dbuser'] }}
    - connection_user: root
    - connection_pass: {{ pillar['ocs_mysql_root'] }}
    - connection_db: ocsweb

ocs_dbuser_ocsweb:
  mysql_grants.present:
    - grant: all privileges
    - database: ocsweb.*
    - user: ocs_dbuser
    - connection_user: root
    - connection_pass: {{ pillar['ocs_mysql_root'] }}

# install newest version of OCS Inventory
/opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz:
  file.managed:
    - source: salt://files/linux/ocs/server/OCSNG_UNIX_SERVER_2.4.1.tar.gz
'cd /opt && tar -xf /opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz':
  cmd.run:
  - onchanges:
      - file: /opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz
'yes "" | sh setup.sh':
  cmd.run:
    - onchanges:
      - file: /opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz
    - cwd: /opt/OCSNG_UNIX_SERVER_2.4.1

# remove setup file for security
'/usr/share/ocsinventory-reports/ocsreports/install.php':
  file.absent

# modify config files
/usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php:
  file.managed:
    - contents_pillar: ocs_dbconfig.inc.php
perlsetenv_ocs_db_user:
  file.line:
    - name: /etc/apache2/conf-available/z-ocsinventory-server.conf
    - mode: replace
    - content: 'PerlSetEnv OCS_DB_USER ocs_dbuser'
    - match: 'PerlSetEnv OCS_DB_USER ocs'
perlsetvar_ocs_db_pwd:
  file.line:
    - name: /etc/apache2/conf-available/z-ocsinventory-server.conf
    - mode: replace
    - content: 'PerlSetVar OCS_DB_PWD {{ pillar['ocs_dbuser'] }}'
    - match: 'PerlSetVar OCS_DB_PWD ocs'

/var/www/html/index.html:
  file.managed:
    - contents_pillar: ocs_index.html

# secure ocs
/etc/apache2/ssl:
  file.directory:
    - mode: 0700
/etc/apache2/ssl/ocs.key:
  file.managed:
    - contents_pillar: ocs.key
    - mode: 0600
/etc/apache2/ssl/ocs.crt:
  file.managed:
    - contents_pillar: ocs.crt
    - mode: 0600
apache_ssl_crt:
  file.line:
    - name: /etc/apache2/sites-available/default-ssl.conf
    - mode: replace
    - content: 'SSLCertificateFile /etc/apache2/ssl/ocs.crt'
    - match: '/etc/ssl/certs/ssl-cert-snakeoil.pem'
apache_ssl_key:
  file.line:
    - name: /etc/apache2/sites-available/default-ssl.conf
    - mode: replace
    - content: 'SSLCertificateKeyFile  /etc/apache2/ssl/ocs.key'
    - match: 'SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key'
'a2ensite default-ssl && a2enmod ssl':
  cmd.run:
    - onchanges:
      - file: /etc/apache2/ssl/ocs.crt

# enable apache config
'a2enconf ocsinventory-reports && a2enconf z-ocsinventory-server && a2enconf zz-ocsinventory-restapi & chown -R www-data:www-data /var/lib/ocsinventory-reports/':
  cmd.run:
    - onchanges:
      - file: /opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz

# remove software deployment feature
/usr/share/ocsinventory-reports/ocsreports/require/function_telediff.php:
  file.absent
'/usr/share/ocsinventory-reports/ocsreports/config/main_menu.xml':
  file.managed:
    - contents_pillar: ocs_main_menu.xml
'/usr/share/ocsinventory-reports/ocsreports/config/computer/menu.xml':
  file.managed:
    - contents_pillar: ocs_menu.xml

# customize banner and favicon
'/usr/share/ocsinventory-reports/ocsreports/themes/OCS/banniere.png':
  file.managed:
    - source: 'salt://files/linux/ocs/server/banniere.png'
'/usr/share/ocsinventory-reports/ocsreports/favicon.ico':
  file.managed:
    - source: 'salt://files/linux/ocs/server/favicon.ico'

apache2:
  service.running:
      - enable: True
      - restart: True
      - watch:
        - file: '/usr/share/ocsinventory-reports/ocsreports/favicon.ico'
        - file: /opt/OCSNG_UNIX_SERVER_2.4.1.tar.gz

# inlcude mysql dump cronjob
include:
  - linux.cron.mysqldump
/usr/local/scripts/mysqldump.sh:
  file.managed:
    - makedirs: True
    - contents_pillar: ocs_mysqldump.sh
    - mode: 600
