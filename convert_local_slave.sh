#!/bin/bash
################################################################################
# This script will handle the conversion of a slave nameserver to run bind in  #
# docker.                                                                      #
#                                                                              #
# This requires that deploy_local_slave.sh has been run in the past.           #
################################################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR}

USER=`whoami`
if [ "${USER}" != "root" ]; then
	echo "This script must run as root."
	exit 1;
fi;

if [ ! -e /etc/bind ]; then
	echo "This script should only be run on a server that previously ran bind."
	exit 1;
fi;

if [ ! -e "/etc/bind/server_settings.conf" ]; then
	echo "This script should only be run on a server that previously ran bind."
	exit 1;
fi;

if [ ! -e "/etc/bind/catalog.db" ]; then
	echo "This script should only be run on a server that previously ran bind."
	exit 1;
fi;

if [ ! -e "/etc/bind/cat-zones" ]; then
	echo "This script should only be run on a server that previously ran bind."
	exit 1;
fi;

DOCKER=`which docker`
if [ "${DOCKER}" = "" ]; then
	echo "Please install docker on this host."
	exit 1;
fi;

DOCKERCOMPOSE=`which docker-compose`
if [ "${DOCKERCOMPOSE}" = "" ]; then
	echo "Please install docker-compose on this host."
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

BACKUPDIR="/etc/bind-backup-$(date '+%Y-%m-%d-%H:%M:%S')"

echo "Saving old bind config dir."
cp -Rf /etc/bind ${BACKUPDIR}

echo "Removing old slave server config."
update-rc.d named disable
apt-get -y purge bind bind9


if [ -e /etc/systemd/system/fakeCatalog.service ]; then
	service fakeCatalog stop
	systemctl disable fakeCatalog
	rm /etc/systemd/system/fakeCatalog.service
	systemctl daemon-reload
fi;

if [ -e /etc/cron.hourly/fakeCatalog_monitor.sh ]; then
	rm /etc/cron.hourly/fakeCatalog_monitor.sh
fi

echo "Disable systemd-resolved"
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved

echo "Creating data directory."
mkdir -p data/keys data/zones

echo "Copying old server data"
cp -Rfv "${BACKUPDIR}/catalog.db" "${BACKUPDIR}/server_settings.conf" "${BACKUPDIR}/cat-zones" data

echo "Starting Server"
docker-compose up -d

exit 0;
