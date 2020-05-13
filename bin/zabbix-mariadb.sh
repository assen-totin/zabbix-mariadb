#!/bin/bash

# MariaDB AX databases autodiscovery and size collection for Zabbix

export HOME=/var/lib/zabbix

COMMAND=$1
MARIADB_CLI="/usr/local/bin/zabbix-mariadb -N mysql"

SYSTEM_DB='"calpontsys", "columnstore_info", "infinidb_querystats", "infinidb_vtable", "information_schema", "mysql", "performance_schema"'

# Function to get DB size from transactional storage (in MB)
db_size_tx() {
	VALUE=$(echo "SELECT CAST(SUM(data_length + index_length)/1048576 AS UNSIGNED) AS size FROM information_schema.tables WHERE table_schema='$1';" | $MARIADB_CLI)
	[ x$VALUE == 'x' ] && VALUE=0
	SIZE=$((SIZE + VALUE))
}

# Function to get DB size from ColumnStore
db_size_ax() {
	DATA=$(echo "CALL columnstore_info.table_usage('$1', NULL)" | $MARIADB_CLI 2>/dev/null | awk '{print $7":"$8}')

	for ENTRY in $DATA; do
		VALUE=$(echo $ENTRY | awk -F ':' '{print $1}')
		UNITS=$(echo $ENTRY | awk -F ':' '{print $2}')

		case $UNITS in
			"MB")
				# Round down to a full megabyte
				VALUE=$(awk -vp=$VALUE 'BEGIN{printf "%.0f" ,p}')
				;;
			"GB")
				# Convert to megabytes
				# NB: bash does not know how to multiply decimals, hence resort to awk
				VALUE=$(awk -vp=$VALUE 'BEGIN{printf "%.0f" ,p * 1024}')
				;;
			"TB")
				# Convert to megabytes
				# NB: bash does not know how to multiply decimals, hence resort to awk
				VALUE=$(awk -vp=$VALUE 'BEGIN{printf "%.0f" ,p * 1024 * 1024}')
				;;
               *)
				# Skip smaller values 
				VALUE=0
		esac

		SIZE=$((SIZE + VALUE))
	done
}


# Function to get DB size from disk
db_disk_tx() {
	MARIADB_DATADIR=$(echo "SHOW GLOBAL VARIABLES WHERE Variable_name='datadir'" | $MARIADB_CLI | awk '{print $2}')
	SIZE=$(sudo du -s -b "$MARIADB_DATADIR$1" | awk '{print $1}')
}

case $COMMAND in
	"discover")
		_PREV=0
		echo -n '{"data":['

		# Discover databases
		DATABASES=$(echo "SELECT DISTINCT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA NOT IN ($SYSTEM_DB)" | $MARIADB_CLI)
		for DATABASE in $DATABASES; do
			[ $_PREV -gt 0 ] && echo -n ','
			echo -n '{'
			echo -n '"{#MARIADB.DB.NAME}":"'
			echo -n $DATABASE
			echo -n '"'
			echo -n '}'
			_PREV=1
		done

		echo ']}'
		;;

	"size")
		SIZE=0

		db_size_tx $2
		db_size_ax $2

		echo $SIZE
		;;

	"disk")
		SIZE=0

		db_disk_tx $2

		echo $SIZE
		;;
esac

