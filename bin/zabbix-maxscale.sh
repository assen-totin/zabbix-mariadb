#!/bin/bash

# MaxScale clients autodiscovery and status collection for Zabbix
# NB: Requires maxsctrl which is available from MaxScale 2.2 onwards.

COMMAND=$1
ARGUMENT=$2
HOST=${3}
MAXCTRL="/usr/local/bin/zabbix-maxctrl --tsv"

case $COMMAND in
	"services")
		case ${ARGUMENT} in
			"discover")
				_PREV=0
				echo -n '{"data":['
				for SERVICE in $($MAXCTRL list services | awk '{print $1}') ; do
					[ $_PREV -gt 0 ] && echo -n ','
					echo -n '{'
					echo -n '"{#MAXSCALE.SERVICE.NAME}":"'
					echo -n $SERVICE
					echo -n '"'
					echo -n '}'
					_PREV=1
				done
				echo ']}'
				;;

			"connections")
				$MAXSTRL list services | grep ${HOST} | awk '{print $3}'
				;;

			*)
				echo "Unknown argument: $ARGUMENT"
				;;
		esac
		;;

	"servers")
		case ${ARGUMENT} in
			"discover")
				_PREV=0
				echo -n '{"data":['
				for SERVICE in $($MAXCTRL list servers | awk '{print $1}') ; do
					[ $_PREV -gt 0 ] && echo -n ','
					echo -n '{'
					echo -n '"{#MAXSCALE.SERVER.NAME}":"'
					echo -n $SERVICE
					echo -n '"'
					echo -n '}'
					_PREV=1
				done
				echo ']}'
				;;

			"connections")
				$MAXCTRL list servers | grep ${HOST} | awk '{print $4}'
				;;

			"state" )
				$MAXCTRL list servers | grep ${HOST} | awk -F '\t' '{print $5}' | grep Running | wc -l
				;;

			*)
				echo "Unknown argument: $ARGUMENT"
				;;
		esac
		;;


	*)
		echo "Unknown command: $COMMAND"
		;;
esac

