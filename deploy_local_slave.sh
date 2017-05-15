#!/bin/bash
################################################################################
# This script will handle the automatic setup of a slave nameserver	locally    #
# rather than via docker.                                                      #
#                                                                              #
# This requires that bind9 from apt is at least 9.11 or later.     	           #
################################################################################
# apt-get update && apt-get -y install git && git clone https://github.com/shanemcc/mydnshost-bind && cd mydnshost-bind && ./deploy_local_slave.sh
################################################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR}

USER=`whoami`
if [ "${USER}" != "root" ]; then
	echo "This script must run as root."
	exit 1;
fi;

echo "Setting up slave server."
echo ""

HASBIND=`dpkg --get-selections | egrep "^bind9[[:space:]]"`
if [ "${HASBIND}" = "" ]; then
	echo "Installing bind...";
	apt-get -y install bind9 bind9utils
	update-rc.d bind9 enable
fi;

echo "Removing old bind config...";
rm -Rfv "/etc/bind/"*;

echo "Adding new bind config...";
TEMPDIR=`mktemp -d`
git clone https://github.com/nguoianphu/docker-dns ${TEMPDIR}

cp -Rfv "${TEMPDIR}/bind/"* "/etc/bind/";
cp -Rfv "${DIR}/bind/"* "/etc/bind/";
rm -Rf "${TEMPDIR}"

mkdir -p /etc/bind/dynamic
mkdir -p /etc/bind/data
touch /etc/bind/data/named.run

rm -Rfv "/etc/bind/named.conf";
ln -sf "/etc/bind/named.slave.conf" "/etc/bind/named.conf";

echo "Creating cat-zones directory...";
mkdir /etc/bind/cat-zones/

TESTCONF=`mktemp`
echo 'options { catalog-zones { }; };' >> ${TESTCONF}
named-checkconf ${TESTCONF};
if [ "${?}" -eq 1 ]; then
	OLDVERSION="1"
fi;
rm ${TESTCONF}

if [ "${OLDVERSION}" = "1" ]; then
	apt-get -y install inotify-tools
	echo "Removing Catalog-Zones configuration...";
	sed -i -e '1h;2,$H;$!d;g' -e 's/catalog-zones {[^}]*};[^}]*};[^}]*};//g' /etc/bind/named.slave.conf

	echo "Installing fakeCatalog.sh";
	ln -sf /etc/bind/fakeCatalog.service /etc/systemd/system/fakeCatalog.service
	systemctl daemon-reload
fi;

echo "Fixing ownership";
chown -Rf bind:bind /etc/bind

echo "Restarting bind."
service bind9 stop
service bind9 start

if [ "${OLDVERSION}" = "1" ]; then
	service fakeCatalog stop
	service fakeCatalog start
fi;
