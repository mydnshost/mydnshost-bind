#!/bin/bash

set -xe

if [ "$1" == "" ]; then
	echo "Starting BIND: ${RUNMODE}"

	if [ "${RUNMODE}" == "SLAVE" ]; then
		exec named -c /etc/bind/named.slave.conf -g
	elif [ "${RUNMODE}" == "MASTER" ]; then
		ZONEFILE="/etc/bind/named.local.zones"
		echo "" > "${ZONEFILE}"

		cat /bind/catalog.db | egrep "IN[[:space:]]+PTR" | awk '{print $4}' | while read ZONE; do
			echo 'zone "'${ZONE}'" ' >> ${ZONEFILE}
			echo '	type master;' >> ${ZONEFILE}
			echo '	file "/bind/zones/'${ZONE}'.db";' >> ${ZONEFILE}
			echo '};' >> ${ZONEFILE}
			echo '' >> ${ZONEFILE}
		done;

		exec named -c /etc/bind/named.master.conf -g
	fi;
fi
