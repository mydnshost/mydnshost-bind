#!/bin/bash

set -xe

if [ "$1" == "" ]; then
	if [ "${MASTER}" = "" -o "${SLAVES}" = "" ]; then
		echo "MASTER and SLAVES environmemt variables must be set."
		echo ""
		echo "Example:"
		echo 'MASTER="1.1.1.1;"'
		echo 'SLAVES="2.2.2.2; 3.3.3.3; 4.4.4.4;"'
		exit 1;
	fi;

	if [ "${STATISTICS}" = "" ]; then
		STATISTICS="${MASTER}";
	fi;

	if [ "${RNDCKEY}" = "" ]; then
		echo "Generating RNDC Key..."

		RNDCKEY=$(rndc-confgen -A hmac-md5 | grep -m1 secret | awk -F\" '{print $2}')
	fi;
	echo 'key "rndc-key" { algorithm hmac-md5; secret "'"${RNDCKEY}"'"; };' > /etc/bind/rndc.key.conf

	echo "Starting BIND: ${RUNMODE}"

	if [ "${RUNMODE}" == "SLAVE" ]; then
		cp "/etc/bind/named.slave.conf.template" "/etc/bind/named.slave.conf";
		sed -i 's/%%MASTER%%/'"${MASTER}"'/g' "/etc/bind/named.slave.conf"
		sed -i 's/%%SLAVES%%/'"${SLAVES}"'/g' "/etc/bind/named.slave.conf"
		sed -i 's/%%STATISTICS%%/'"${STATISTICS}"'/g' "/etc/bind/named.slave.conf"

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

			echo 'zone "'${ZONE}'" { type master; file "/bind/zones/'${ZONE}'.db"; auto-dnssec maintain; inline-signing yes; ' >> ${ZONEFILE}

			if [ "${ALLOWED_TRANSFER}" != "" ]; then
				ALLOWED_TRANSFER=$(echo "${ALLOWED_TRANSFER}" | sed -re 's#[12]:([^/]+)/(32|128)#\1;#g');
				echo 'allow-transfer { '${ALLOWED_TRANSFER}' }; ' >> ${ZONEFILE}
			fi;

			echo ' };' >> ${ZONEFILE}


			auto-dnssec maintain;
		done;

		cp "/etc/bind/named.master.conf.template" "/etc/bind/named.master.conf";
		sed -i 's/%%MASTER%%/'"${MASTER}"'/g' "/etc/bind/named.master.conf"
		sed -i 's/%%SLAVES%%/'"${SLAVES}"'/g' "/etc/bind/named.master.conf"
		sed -i 's/%%STATISTICS%%/'"${STATISTICS}"'/g' "/etc/bind/named.master.conf"

		exec named -c /etc/bind/named.master.conf -g
	else
		echo "Unknown RUNMODE."
	fi;
fi
