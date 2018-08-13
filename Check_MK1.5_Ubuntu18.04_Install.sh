#!/bin/bash

# first make executable with chmod +x filename.sh
# then run with ./filename.sh
${CHECK_MK_VERSION}
# Version number Check_MK to install
CHECK_MK_VERSION="1.5.0p1"
CODENAME="bionic"

# Install prereqs

apt-get -y install apache2 apache2-bin apache2-data apache2-utils binutils binutils-common binutils-x86-64-linux-gnu \
debugedit dialog fontconfig fontconfig-config fonts-dejavu-core fonts-liberation fping freeradius-common freeradius-config \
freeradius-utils graphviz lcab libann0 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libarchive13 libavahi-client3 \
libavahi-common-data libavahi-common3 libbinutils libcairo2 libcdt5 libcgraph6 libcups2 libdatrie1 libdbi-perl libdbi1 libdw1 libevent-1.4-2 \
libfile-copy-recursive-perl libfl2 libfontconfig1 libfreeradius3 libgd3 libgraphite2-3 libgsf-1-114 libgsf-1-common libgts-0.7-5 libgts-bin \
libgvc6 libgvpr2 libharfbuzz0b libice6 libjansson4 libjbig0 libjpeg-turbo8 libjpeg8 liblab-gamut1 liblcms2-2 libldb1 libltdl7 liblua5.2-0 \
libnet-snmp-perl libnspr4 libnss3 libpango-1.0-0 libpango1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpangox-1.0-0 libpangoxft-1.0-0 libpathplan4 \
libpixman-1-0 libpoppler73 libpython-stdlib libpython2.7 libpython2.7-minimal libpython2.7-stdlib librpm8 librpmbuild8 librpmio8 librpmsign8 libsensors4 \
libsm6 libsmbclient libsnmp-base libsnmp-perl libsnmp30 libsodium23 libtalloc2 libtdb1 libtevent0 libthai-data libthai0 libtiff5 libtirpc1 libwbclient0 \
libwebp6 libxaw7 libxcb-render0 libxcb-shm0 libxft2 libxmu6 libxpm4 libxrender1 libxt6 make php-cgi php-cli php-common php-gd php-pear php-sqlite3 php-xml \
php7.2-cgi php7.2-cli php7.2-common php7.2-gd php7.2-json php7.2-opcache php7.2-readline php7.2-sqlite3 php7.2-xml poppler-data poppler-utils pyro python \
python-crypto python-ldb python-minimal python-samba python-talloc python-tdb python2.7 python2.7-minimal rpcbind rpm rpm-common rpm2cpio samba-common \
samba-common-bin samba-libs smbclient snmp ssl-cert traceroute unzip update-inetd x11-common xinetd


# If apt fails to run completely the rest of this isn't going to work...
if [ $? -ne 0 ]; then   echo "apt-get failed to install all required dependencies"   exit
fi

# Download OCS Inventory Server
wget -O check-mk-raw-${CHECK_MK_VERSION}_0.${CODENAME}_amd64.deb https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}_0.${CODENAME}_amd64.deb

if [ $? -ne 0 ]; then   echo "Failed to download check-mk-raw-${CHECK_MK_VERSION}.tar.gz"   echo "https://mathias-kettner.de/support/${CHECK_MK_VERSION}/check-mk-raw-${CHECK_MK_VERSION}_0.$CODENAME_amd64.deb"   exit
fi


# Install Check_MK Raw Edition
dpkg -i check-mk-raw-${CHECK_MK_VERSION}_0.${CODENAME}_amd64.deb

# create and start "monitoring" site
omd create monitoring
omd start monitoring

echo -e "Installation complete"
