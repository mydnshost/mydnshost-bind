#!/bin/sh
################################################################################
# This script will handle the automatic setup of a slave nameserver	           #
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
rm -Rfv "/etc/bind/*";

echo "Adding new bind config...";
cp -Rfv "${DIR}/bind/*" "/etc/bind/";

rm -Rfv "/etc/bind/named.conf";
ln -sf "/etc/bind/named.slave.conf" "/etc/bind/named.conf";

echo "Creating cat-zones directory...";
mkdir /etc/bind/cat-zones/
chown bind:bind /etc/bind/cat-zones/

echo "Restarting bind."
RNDC=`which rndc`
${RNDC} reload
