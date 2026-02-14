#!/bin/bash

CATZONE="/etc/bind/catalog.db"
CATNAME="catalog.invalid"
MONITOR_SCRIPT="/etc/bind/fakeCatalog_monitor.sh"

MASTER="";
SLAVES="";

if [ -e "/etc/bind/server_settings.conf" ]; then
	source "/etc/bind/server_settings.conf"
fi;

while true; do
	if [ -e "${CATZONE}" ]; then
		TEMPFILE=`mktemp`
		named-compilezone -f raw -F text -o - "${CATNAME}" "${CATZONE}" 2>&1 | egrep "IN[[:space:]]+PTR" | awk -F" PTR " '{print $2}' | sed 's/.$//' >> "${TEMPFILE}"

		cat "${TEMPFILE}" | while read ZONE; do
			if [ ! -e "/etc/bind/cat-zones/${ZONE}.db" ]; then
				echo "Adding new zone: ${ZONE}"
				rndc addzone "${ZONE}" '{ type secondary; notify no; primaries { '"${MASTER}"' }; file "/etc/bind/cat-zones/'"${ZONE}"'.db"; };'
				touch "/etc/bind/cat-zones/${ZONE}.db"
			fi;
		done;

		ls -1 /etc/bind/cat-zones/ | while read ZONE; do
			EXT=${ZONE##*.}
			ZONE=${ZONE%.*}
			if [ "${EXT}" = "db" -a -e "/etc/bind/cat-zones/${ZONE}.db" ]; then
				INCAT=`cat ${TEMPFILE} | grep "^${ZONE}$"`

				if [ "${INCAT}" = "" ]; then
					echo "Removing zone: ${ZONE}"
					rndc delzone "${ZONE}"
					rm "/etc/bind/cat-zones/${ZONE}.db"
				fi;
			fi;
		done;

		rm ${TEMPFILE}
	else
		touch "${CATZONE}"
	fi;

	if [ -e "${MONITOR_SCRIPT}" ]; then
		/bin/sh "${MONITOR_SCRIPT}"
	fi;

	inotifywait --timeout 86400 "${CATZONE}"

	sleep 5
done


