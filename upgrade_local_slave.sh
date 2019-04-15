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
STATISTICS="";
RNDCKEY="";

if [ -e "/etc/bind/server_settings.conf" ]; then
	source "/etc/bind/server_settings.conf"
fi;

if [ "${MASTER}" = "" -o "${SLAVES}" = "" ]; then
	echo "MASTER and SLAVES settings must be defined in /etc/bind/server_settings.conf before running this."
	echo ""
	echo "Example:"
	echo 'MASTER="1.1.1.1;"'
	echo 'SLAVES="2.2.2.2; 3.3.3.3; 4.4.4.4;"'
	exit 1;
fi;

if [ "${STATISTICS}" = "" ]; then
	STATISTICS="${MASTER}";
fi;

echo "Upgrading up slave server."

HASBIND9=`dpkg --get-selections | egrep "^bind9[[:space:]].*[[:space:]]install"`
if [ "${HASBIND9}" != "" ]; then
	echo "Removing bind9...";
	service bind9 stop
	update-rc.d bind9 disable
	apt-get -y remove bind9 bind9utils
fi;

HASBIND=`dpkg --get-selections | egrep "^bind[[:space:]].*[[:space:]]install"`
if [ "${HASBIND}" = "" ]; then
	echo "Installing bind...";
	apt-get -y install software-properties-common
	add-apt-repository -y ppa:isc/bind
	apt-get update

	apt-get -y install bind
	update-rc.d bind enable
fi;

echo '' > /etc/default/bind
echo 'RESOLVCONF=no' >> /etc/default/bind
echo 'OPTIONS="-u bind"' >> /etc/default/bind

cp -Rfv "${DIR}/bind/"* "/etc/bind/";

rm -Rfv "/etc/bind/named.conf";
cp "/etc/bind/named.slave.conf.template" "/etc/bind/named.conf";
sed -i 's/%%MASTER%%/'"${MASTER}"'/g' "/etc/bind/named.conf"
sed -i 's/%%SLAVES%%/'"${SLAVES}"'/g' "/etc/bind/named.conf"
sed -i 's/%%STATISTICS%%/'"${STATISTICS}"'/g' "/etc/bind/named.conf"

if [ "${RNDCKEY}" = "" ]; then
	echo "Generating RNDC Key..."

	RNDCKEY=$(rndc-confgen -A hmac-md5 | grep -m1 secret | awk -F\" '{print $2}')
	echo 'RNDCKEY="'"${RNDCKEY}"'"' >> "/etc/bind/server_settings.conf"
fi;

echo 'key "rndc-key" { algorithm hmac-md5; secret "'"${RNDCKEY}"'"; };' > /etc/bind/rndc.key.conf

TESTCONF=`mktemp`
echo 'options { catalog-zones { }; };' >> ${TESTCONF}
named-checkconf ${TESTCONF};
if [ "${?}" -eq 1 ]; then
	OLDVERSION="1"
fi;
rm ${TESTCONF}

CHANGECATALOG=0

if [ "${OLDVERSION}" = "1" ]; then
	echo "Removing Catalog-Zones configuration...";
	sed -i -e '1h;2,$H;$!d;g' -e 's/catalog-zones {[^}]*};[^}]*};[^}]*};//g' /etc/bind/named.conf

	if [ ! -e /etc/systemd/system/fakeCatalog.service ]; then
		echo "Installing fakeCatalog.sh";
		systemctl enable /etc/bind/fakeCatalog.service
	fi;

	if [ -e /etc/cron.hourly/fakeCatalog_monitor.sh ]; then
		rm /etc/cron.hourly/fakeCatalog_monitor.sh
	fi
	CHANGECATALOG=1
elif [ -e /etc/systemd/system/fakeCatalog.service ]; then
	service fakeCatalog stop
	systemctl disable fakeCatalog

	if [ -e /etc/bind/fakeCatalog_monitor.sh ]; then
		ln -s /etc/bind/fakeCatalog_monitor.sh /etc/cron.hourly/fakeCatalog_monitor.sh
	fi;
	CHANGECATALOG=1
fi;
systemctl daemon-reload

echo "Fixing ownership";
chown -Rf bind:bind /etc/bind

if [ -e "/etc/apparmor.d/local/usr.sbin.named" ]; then
	echo "Fixing AppArmor";
	echo   "/etc/bind/** rw," > /etc/apparmor.d/local/usr.sbin.named
	service apparmor reload
fi;

echo "Reloading bind."
service bind stop

if [ "${CHANGECATALOG}" == "1" ]; then
	rm /etc/bind/_default.nzd*
fi;

service bind start

if [ "${OLDVERSION}" = "1" ]; then
	service fakeCatalog stop
	service fakeCatalog start
fi;
