#!/bin/bash
################################################################################
# This script will handle the automatic upgrade of a slave nameserver locally  #
# rather than via docker.                                                      #
#                                                                              #
# This requires that deploy_local_slave.sh has been run in the past.           #
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

MASTER="";
SLAVES="";
RNDCKEY="";

if [ -e "/etc/bind/server_settings.conf" ]; then
	source "/etc/bind/server_settings.conf"
fi;

if [ "${RNDCKEY}" = "" ]; then
	echo "Generating RNDC Key..."

	RNDCKEY=$(rndc-confgen -A hmac-md5 | grep -m1 secret | awk -F\" '{print $2}')
	echo 'RNDCKEY="'"${RNDCKEY}"'"' >> "/etc/bind/server_settings.conf"
	echo 'key "rndc-key" { algorithm hmac-md5; secret "'"${RNDCKEY}"'"; };' > /etc/bind/rndc.key.conf
fi;

if [ "${MASTER}" = "" -o "${SLAVES}" = "" ]; then
	echo "MASTER and SLAVES settings must be defined in /etc/bind/server_settings.conf before running this."
	echo ""
	echo "Example:"
	echo 'MASTER="1.1.1.1;"'
	echo 'SLAVES="2.2.2.2; 3.3.3.3; 4.4.4.4;"'
	exit 1;
fi;

echo "Upgrading up slave server."

cp -Rfv "${DIR}/bind/"* "/etc/bind/";

rm -Rfv "/etc/bind/named.conf";
cp "/etc/bind/named.slave.conf.template" "/etc/bind/named.conf";
sed -i 's/%%MASTER%%/'"${MASTER}"'/g' "/etc/bind/named.conf"
sed -i 's/%%SLAVES%%/'"${SLAVES}"'/g' "/etc/bind/named.conf"

TESTCONF=`mktemp`
echo 'options { catalog-zones { }; };' >> ${TESTCONF}
named-checkconf ${TESTCONF};
if [ "${?}" -eq 1 ]; then
	OLDVERSION="1"
fi;
rm ${TESTCONF}

if [ "${OLDVERSION}" = "1" ]; then
	echo "Removing Catalog-Zones configuration...";
	sed -i -e '1h;2,$H;$!d;g' -e 's/catalog-zones {[^}]*};[^}]*};[^}]*};//g' /etc/bind/named.conf

	echo "Installing fakeCatalog.sh";
	systemctl enable /etc/bind/fakeCatalog.service
	systemctl daemon-reload
fi;

echo "Fixing ownership";
chown -Rf bind:bind /etc/bind

echo "Reloading bind."
service bind9 reload

if [ "${OLDVERSION}" = "1" ]; then
	service fakeCatalog restart
fi;