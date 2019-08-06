#!/bin/bash
################################################################################
# This script will handle the automatic setup of a slave nameserver locally    #
# rather than via docker.                                                      #
#                                                                              #
# This requires that bind9 from apt is at least 9.11 or later.                 #
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

if [ "${MASTER}" = "" -o "${SLAVES}" = "" ]; then
	echo "You must specify MASTER and SLAVES environment variables before running this."
	echo ""
	echo "Example:"
	echo 'export MASTER="1.1.1.1;"'
	echo 'export SLAVES="2.2.2.2; 3.3.3.3; 4.4.4.4;"'
	echo "${0}"
	exit 1;
fi;

if [ "${STATISTICS}" = "" ]; then
	STATISTICS="${MASTER}";
fi;

echo "Setting up slave server."
echo ""

HASBIND9=`dpkg --get-selections | egrep "^bind9[[:space:]].*[[:space:]]install"`
if [ "${HASBIND9}" != "" ]; then
	echo "Installing bind...";
	apt-get -y install software-properties-common
	add-apt-repository -y ppa:isc/bind
	apt-get update

	apt-get -y install bind9
	update-rc.d bind9 enable
fi;

echo '' > /etc/default/bind
echo 'RESOLVCONF=no' >> /etc/default/bind
echo 'OPTIONS="-u bind"' >> /etc/default/bind

echo "Removing old bind config...";
rm -Rfv "/etc/bind/"*;

echo "Adding new bind config...";

cp -Rfv "${DIR}/bind/"* "/etc/bind/";

mkdir -p /etc/bind/dynamic
mkdir -p /etc/bind/data
touch /etc/bind/data/named.run

rm -Rfv "/etc/bind/named.conf";
cp "/etc/bind/named.slave.conf.template" "/etc/bind/named.conf";
sed -i 's/%%MASTER%%/'"${MASTER}"'/g' "/etc/bind/named.conf"
sed -i 's/%%SLAVES%%/'"${SLAVES}"'/g' "/etc/bind/named.conf"
sed -i 's/%%STATISTICS%%/'"${STATISTICS}"'/g' "/etc/bind/named.conf"

if [ "${RNDCKEY}" = "" ]; then
	echo "Generating RNDC Key..."

	RNDCKEY=$(rndc-confgen -A hmac-md5 | grep -m1 secret | awk -F\" '{print $2}')
fi;

echo 'MASTER="'"${MASTER}"'"' > "/etc/bind/server_settings.conf"
echo 'SLAVES="'"${SLAVES}"'"' >> "/etc/bind/server_settings.conf"
echo 'STATISTICS="'"${STATISTICS}"'"' >> "/etc/bind/server_settings.conf"
echo 'RNDCKEY="'"${RNDCKEY}"'"' >> "/etc/bind/server_settings.conf"

echo "Creating cat-zones directory...";
mkdir /etc/bind/cat-zones/

echo 'key "rndc-key" { algorithm hmac-md5; secret "'"${RNDCKEY}"'"; };' > /etc/bind/rndc.key.conf

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
	sed -i -e '1h;2,$H;$!d;g' -e 's/catalog-zones {[^}]*};[^}]*};[^}]*};//g' /etc/bind/named.conf

	echo "Installing fakeCatalog.sh";
	systemctl enable /etc/bind/fakeCatalog.service
else
	if [ -e /etc/bind/fakeCatalog_monitor.sh ]; then
		ln -s /etc/bind/fakeCatalog_monitor.sh /etc/cron.hourly/fakeCatalog_monitor.sh
	fi;
fi;

echo "Ensuring bind restarts automatically.";
RESTART=$(grep "Restart=always" /lib/systemd/system/bind9.service)
if [ "" = "${RESTART}" ]; then
	echo "Updating systemd file for bind...";
	sed -i 's/\[Service\]/[Service]\nRestart=always/' /lib/systemd/system/bind9.service
fi;

systemctl daemon-reload

echo "Fixing ownership";
chown -Rf bind:bind /etc/bind

if [ -e "/etc/apparmor.d/local/usr.sbin.named" ]; then
	echo "Fixing AppArmor";
	echo   "/etc/bind/** rw," > /etc/apparmor.d/local/usr.sbin.named
	service apparmor reload
fi;

echo "Restarting bind."
service bind9 stop
service bind9 start

if [ "${OLDVERSION}" = "1" ]; then
	service fakeCatalog stop
	service fakeCatalog start
fi;
