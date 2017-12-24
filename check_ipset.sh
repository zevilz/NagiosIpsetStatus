#!/bin/bash
# Nagios plugin for check ipset status.
# URL: https://github.com/zevilz/NagiosIpsetStatus
# Author: Alexandr "zEvilz" Emshanov
# License: MIT
# Version: 1.0.0

usage()
{
	echo
	echo "Usage: bash $0 [options]"
	echo
	echo "Nagios plugin for check fail2ban status."
	echo
	echo "Options:"
	echo
	echo "    -h, --help              Shows this help. Only for directly usage."
	echo
	echo "    -s, --set-name          Specify ipset set name. Only for directly usage."
	echo
	echo "    -n, --nagios            Enable Nagios/Icinga usage. Showing ipset "
	echo "                            status requiring use log file."
	echo
	echo "    -p <path>,              Specify path to log file with ipset status. "
	echo "    --log-path=<path>       Only for Nagios/Icinga usage."
	echo
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
		echo "ERROR! Ipset not found."
		exit 2
	fi
}
check_set()
{
	ipset -L "$IPSET_SET_NAME" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "ERROR! Set \"$IPSET_SET_NAME\" not exists."
		exit 2
	fi
}
checkLog()
{
	if [[ -z "$IPSET_LOG_FILE" || "$IPSET_LOG_FILE" =~ ^-.*$ ]]; then
		echo "ERROR! Path to log file not set."
		exit 2
	else
		if [[ "$IPSET_LOG_FILE" =~ ^-?.*\/$ ]]
		then
			echo "ERROR! Log filename not set in given path."
			exit 2
		fi
	fi
	if ! [ -f "$IPSET_LOG_FILE" ]; then
		echo "ERROR! Log file not found ($IPSET_LOG_FILE)."
		exit 2
	fi
}
checkParams()
{
	if [ $NAGIOS_USAGE -eq 1 ]; then
		if ! [ -z "$IPSET_SET_NAME" ]; then
			echo "ERROR! It is impossible to use option -s(--set-name) with enabled Nagios/Icinga usage."
			exit 2
		fi
		if [ -z "$IPSET_LOG_FILE" ]; then
			echo "ERROR! Path to log file not set with option -p(--log-path)."
			exit 2
		fi
		if ! [ $HELP -eq 0 ]; then
			echo "ERROR! It is impossible to use option -h(--help) with enabled Nagios/Icinga usage."
			exit 2
		fi
	else
		if [ -z "$IPSET_SET_NAME" ]; then
			echo "ERROR! Set name not given with option -s(--set-name)."
			exit 2
		fi
		if ! [ -z "$IPSET_LOG_FILE" ]; then
			echo "ERROR! It is impossible to use option -p(--log-path) with directly usage."
			exit 2
		fi
	fi
}

BINARY_PATHS="/usr/local/sbin /usr/local/bin /sbin /bin /usr/sbin /usr/bin"
BINARY_PATHS_ARRAY=($BINARY_PATHS)
NAGIOS_USAGE=0
HELP=0
IPSET_LOG_FILE=""
IPSET_SET_NAME=""

while [ 1 ] ; do
	if [ "${1#--log-path=}" != "$1" ] ; then
		IPSET_LOG_FILE="${1#--log-path=}"
	elif [ "$1" = "-p" ] ; then
		shift ; IPSET_LOG_FILE="$1"

	elif [ "${1#--set-name=}" != "$1" ] ; then
		IPSET_SET_NAME="${1#--set-name=}"
	elif [ "$1" = "-s" ] ; then
		shift ; IPSET_SET_NAME="$1"

	elif [[ "$1" = "--help" || "$1" = "-h" ]] ; then
		HELP=1

	elif [[ "$1" = "--nagios" || "$1" = "-n" ]] ; then
		NAGIOS_USAGE=1

	elif [ -z "$1" ] ; then
		break
	else
		echo "ERROR! Unknown key detected!"
		usage
		exit 2
	fi
	shift
done

if [[ $HELP == 1 ]]
then
	usage
	exit 0
fi

if ! [ -z "$IPSET_LOG_FILE" ]; then
	checkLog
fi

checkParams

if [ $NAGIOS_USAGE -eq 0 ]; then
	check_ipset
	check_set
	IPS_COUNT=`ipset -L "$IPSET_SET_NAME" | grep -A999999999 'Members:' | tail -n +2 | wc -l`
	if [ $IPS_COUNT -eq 0 ]; then
		echo "ERROR! \"$IPSET_SET_NAME\" set is empty."
		exit 2
	else
		echo "Ipset OK: $IPS_COUNT IPs in \"$IPSET_SET_NAME\" set."
		exit 0
	fi
else
	cat "$IPSET_LOG_FILE"
	if grep "ERROR" "$IPSET_LOG_FILE" > /dev/null; then
		exit 2
	else
		exit 0
	fi
fi
