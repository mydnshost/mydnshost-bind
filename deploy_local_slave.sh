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

if [ "${RNDCKEY}" = "" ]; then
	echo "Generating RNDC Key..."

	RNDCKEY=$(rndc-confgen -A hmac-md5 | grep -m1 secret | awk -F\" '{print $2}')
fi;

echo "Creating data directory."
mkdir -p data/keys data/zones data/cat-zones

touch data/catalog.db
touch data/catalog.db

echo 'MASTER="'"${MASTER}"'"' > "data/server_settings.conf"
echo 'SLAVES="'"${SLAVES}"'"' >> "data/server_settings.conf"
echo 'STATISTICS="'"${STATISTICS}"'"' >> "data/server_settings.conf"
echo 'RNDCKEY="'"${RNDCKEY}"'"' >> "data/server_settings.conf"

echo "Starting Server"
docker-compose up -d
