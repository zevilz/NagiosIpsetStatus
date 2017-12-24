#!/bin/bash
# Nagios plugin for check ipset status.
# This script for create/update log file.
# URL: https://github.com/zevilz/NagiosIpsetStatus
# Author: Alexandr "zEvilz" Emshanov
# License: MIT
# Version: 1.0.0

checkLogFilePath()
{
	if [[ "$IPSET_LOG_FILE" =~ ^-.*$ ]]; then
		echo "ERROR! Path to log file not set."
		exit 2
	else
		if [[ "$IPSET_LOG_FILE" =~ ^-?.*\/$ ]]; then
			echo "ERROR! Log filename not set in given path."
			exit 2
		fi
	fi
}
check_ipset()
{
	IPSET_ISSET=0
	for p in "${!BINARY_PATHS_ARRAY[@]}" ; do
		if [ -f "${BINARY_PATHS_ARRAY[$p]}/ipset" ]; then
			IPSET_ISSET=1
		fi
	done
	if [ $IPSET_ISSET -eq 0 ]; then
		echo "ERROR! Ipset not found." > "$IPSET_LOG_FILE"
		exit 2
	fi
}
check_set()
{
	ipset -L "$IPSET_SET_NAME" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "ERROR! Set \"$IPSET_SET_NAME\" not exists." > "$IPSET_LOG_FILE"
		exit 2
	fi
}
checkParams()
{
	if [ -z "$IPSET_SET_NAME" ]; then
		echo "ERROR! Set name not given with option -s(--set-name)."
		exit 2
	fi
	if [ -z "$IPSET_LOG_FILE" ]; then
		echo "ERROR! Path to log file not given with option -p(--log-path)."
		exit 2
	fi
}

IPSET_LOG_FILE=""
IPSET_SET_NAME=""
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
BINARY_PATHS=$(echo "$PATH" | sed 's/:/\ /g')
BINARY_PATHS_ARRAY=($BINARY_PATHS)

while [ 1 ] ; do
	if [ "${1#--log-path=}" != "$1" ] ; then
		IPSET_LOG_FILE="${1#--log-path=}"
	elif [ "$1" = "-p" ] ; then
		shift ; IPSET_LOG_FILE="$1"

	elif [ "${1#--set-name=}" != "$1" ] ; then
		IPSET_SET_NAME="${1#--set-name=}"
	elif [ "$1" = "-s" ] ; then
		shift ; IPSET_SET_NAME="$1"

	elif [ -z "$1" ] ; then
		break
	else
		echo "ERROR! Unknown key detected!"
		usage
		exit 2
	fi
	shift
done

checkParams
checkLogFilePath
check_ipset
check_set

IPS_COUNT=`ipset -L "$IPSET_SET_NAME" | grep -A999999999 'Members:' | tail -n +2 | wc -l`
if [ $IPS_COUNT -eq 0 ]; then
	echo "ERROR! \"$IPSET_SET_NAME\" set is empty." > "$IPSET_LOG_FILE"
	exit 2
else
	echo "Ipset OK: $IPS_COUNT IPs in \"$IPSET_SET_NAME\" set." > "$IPSET_LOG_FILE"
	exit 0
fi

chmod 700 "$IPSET_LOG_FILE"
chown nagios:nagios "$IPSET_LOG_FILE"
