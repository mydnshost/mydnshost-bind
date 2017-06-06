#!/bin/bash

set -xe

if [ "$1" == "" ]; then
	echo "Starting BIND: ${RUNMODE}"

	if [ "${RUNMODE}" == "SLAVE" ]; then
		exec named -c /etc/bind/named.slave.conf -g
	elif [ "${RUNMODE}" == "MASTER" ]; then

		# Rebuild _default.nzf
		ZONEFILE="/etc/bind/_default.nzf"
		CATALOGFILE="/bind/catalog.db"

		echo "# New zone file for view: _default" > "${ZONEFILE}"
		echo "# This file contains configuration for zones added by" >> "${ZONEFILE}"
		echo "# the 'rndc addzone' command. DO NOT EDIT BY HAND." >> "${ZONEFILE}"

		cat "${CATALOGFILE}" | egrep "IN[[:space:]]+PTR" | while read LINE; do
			ZONE=$(echo "${LINE}" | awk -F" PTR[[:space:]]+" '{print $2}' | sed 's/.$//');
			HASH=$(echo "${LINE}" | awk -F".zones[[:space:]]+" '{print $1}');
			ALLOWED_TRANSFER=$(cat "${CATALOGFILE}" | egrep "allow-transfer.${HASH}.zones[[:space:]]+" | awk -F" APL " '{print $2}');

			if [ "${ALLOWED_TRANSFER}" = "" ]; then
				echo 'zone "'${ZONE}'" { type master; file "/bind/zones/'${ZONE}'.db"; };' >> ${ZONEFILE}
			else
				ALLOWED_TRANSFER=$(echo "${ALLOWED_TRANSFER}" | sed -re 's#[12]:([^/]+)/(32|128)#\1;#g');
				echo 'zone "'${ZONE}'" { type master; file "/bind/zones/'${ZONE}'.db"; allow-transfer { '${ALLOWED_TRANSFER}' }; };' >> ${ZONEFILE}
			fi;
		done;

		exec named -c /etc/bind/named.master.conf -g
	fi;
fi
