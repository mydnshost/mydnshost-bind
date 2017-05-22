#!/bin/bash

CATZONE="/etc/bind/catalog.db"
CATNAME="catalog.invalid"
MASTER="87.117.249.17"

while true; do
	if [ -e "${CATZONE}" ]; then
		TEMPFILE=`mktemp`
		named-compilezone -f raw -F text -o - "${CATNAME}" "${CATZONE}" 2>&1 | egrep "IN[[:space:]]+PTR" | awk -F" PTR " '{print $2}' | sed 's/.$//' >> "${TEMPFILE}"

		cat "${TEMPFILE}" | while read ZONE; do
			if [ ! -e "/etc/bind/cat-zones/${ZONE}.db" ]; then
				echo "Adding new zone: ${ZONE}"
				rndc addzone "${ZONE}" '{ type slave; notify no; masters { '"${MASTER}"'; }; file "/etc/bind/cat-zones/'"${ZONE}"'.db"; };'
				touch "/etc/bind/cat-zones/${ZONE}.db"
			fi;
		done;

		ls -1 /etc/bind/cat-zones/ | while read ZONE; do
			ZONE=${ZONE%.*}
			INCAT=`cat ${TEMPFILE} | grep "^${ZONE}$"`

			if [ "${INCAT}" = "" ]; then
				echo "Removing zone: ${ZONE}"
				rndc delzone "${ZONE}"
				rm "/etc/bind/cat-zones/${ZONE}.db"
			fi;
		done;

		rm ${TEMPFILE}
	else
		touch "${CATZONE}"
	fi;

	inotifywait --timeout 86400 "${CATZONE}"
	sleep 5
done


