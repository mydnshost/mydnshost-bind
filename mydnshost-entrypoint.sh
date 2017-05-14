#!/bin/bash

set -xe

if [ "$1" == "" ]; then
	echo "Starting BIND: ${RUNMODE}"

	if [ "${RUNMODE}" == "SLAVE" ]; then
		exec named -c /etc/bind/named.slave.conf -g
	elif [ "${RUNMODE}" == "MASTER" ]; then

		# Rebuild _default.nzf
		ZONEFILE="/etc/bind/_default.nzf"

		echo "# New zone file for view: _default" > "${ZONEFILE}"
		echo "# This file contains configuration for zones added by" > "${ZONEFILE}"
		echo "# the 'rndc addzone' command. DO NOT EDIT BY HAND." > "${ZONEFILE}"

		cat /bind/catalog.db | egrep "IN[[:space:]]+PTR" | awk -F" PTR " '{print $2}' | sed 's/.$//' | while read ZONE; do
			echo 'zone "'${ZONE}'" { type master; file "/bind/zones/'${ZONE}'.db"; };' >> ${ZONEFILE}
		done;

		exec named -c /etc/bind/named.master.conf -g
	fi;
fi
