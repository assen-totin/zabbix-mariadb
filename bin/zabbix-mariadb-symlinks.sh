#!/bin/bash

# Autodetect MariaDB node type and set up symlinks for Zabbix
SYMLINK_TX="/usr/local/bin/zabbix-mariadb"
SYMLINK_AX="/usr/local/bin/zabbix-mcsadmin"
SYMLINK_MAXSCALE="/usr/local/bin/zabbix-maxctrl"

# Error handler
error() {
	echo "*** $1 Set the symlinks manually."
	exit 1
}

# Check for stand-alone and TX node
is_node_tx() {
	IS_NODE_TX=$(ps ax | grep mysqld | grep -v grep |wc -l)
}

# Check for ColumnStore UM node
is_node_um() {
	# Check global prefix
	IS_NODE_UM=$(ls -ld /usr/local/mariadb/columnstore 2>/dev/null | wc -l)
	if [ $IS_NODE_UM -gt 0 ] ; then
		UM_PREFIX="/usr/local/mariadb/columnstore"
		return
	fi

	# Check for non-root install
	IS_NODE_UM=$(ls -ld /home/*/mariadb/columnstore 2>/dev/null | wc -l)
	if [ $IS_NODE_UM -gt 1 ] ; then
		error "More than one ColumnsStore home directory found."
	elif [ $IS_NODE_UM -eq 1 ] ; then
		HOME_DIR=$(ls -ld /home/*/mariadb/columnstore | awk -F '/' '{print $3}')
		UM_PREFIX="/home/$HOME_DIR/mariadb/columnstore"
	fi
}

# Check for ColumnStore PM node
is_node_pm() {
	IS_NODE_PM=$(ps ax | grep ProcMon | grep -v grep | wc -l)
}

# Check for MaxScale node
is_node_maxscale() {
	IS_NODE_MAXSCALE=$(ps ax | grep maxscale | grep -v grep | wc -l)
}

# Detect node type
detect_node() {
	# Probe know node types
	is_node_tx
	is_node_pm
	is_node_um
	is_node_maxscale

	# Determine node type
	if [ $IS_NODE_MAXSCALE -gt 0 ] ; then
		NODE_TYPE="maxscale"
	elif [ $IS_NODE_UM -gt 0 ] && [ $IS_NODE_TX -gt 0 ] ; then
		NODE_TYPE="um"
	elif [ $IS_NODE_PM -gt 0 ] ; then
		NODE_TYPE="pm"
	elif [ $IS_NODE_TX -gt 0 ] ; then
		NODE_TYPE="tx"
	else
		error "Unable to detect node type."
	fi
}

# Try to find a binary in the path
find_in_path() {
	FOUND=0
	PROG_PATH=""
	WHICH=$(which $1 2>/dev/null)
	RES=$?
	[ $RES -eq 0 ] && FOUND=1 && PROG_PATH=$(dirname $WHICH)
}

# Try to find a binary in a directory
find_in_dir() {
	PROG_PATH=""
	FOUND=$(ls -l $1/$2 2>/dev/null | wc -l)
	[ $FOUND -gt 0 ] && PROG_PATH="$1"
}

# Try to find a binary in RHEL SCL
find_in_scl(){
	PROG_PATH=""
	FOUND=0

	HAVE_SCL=$(ls -ld /opt/rh/*mariadb* 2>/dev/null | wc -l)
	[ $HAVE_SCL -eq 0 ] && return
	[ $HAVE_SCL -gt 1 ] && error "More than one version of MariaDB from SCL found."

	SCL_DIR=$(ls -d /opt/rh/*mariadb*)
	find_in_dir "$SCL_DIR/root/usr/bin" $1
}

# Create symlinks for MariaDB CLI
symlinks_tx() {
	# Skip if exists
	[ -f $SYMLINK_TX ] && return

	# Try to find where MariaDB CLI is
	find_in_path "mysql"
	[ $FOUND -eq 0 ] && find_in_dir "/usr/local/bin" "mysql"
	[ $FOUND -eq 0 ] && find_in_scl "mysql"
	[ $FOUND -eq 0 ] && error "Unable to find MariaDB CLI binary."

	ln -s "$PROG_PATH/mysql" $SYMLINK_TX
}

# Create symlinks for MariaDB ColumnsStore CLI
symlinks_um() {
	# Check and symlink MariaDB CLI
	if [ ! -f $SYMLINK_TX ] ; then
		find_in_dir "$UM_PREFIX/mysql/bin" "mysql"
		[ $FOUND -eq 0 ] && error "Unable to find MariaDB CLI binary in $UM_PREFIX/mysql/bin"
		ln -s "$UM_PREFIX/mysql/bin/mysql" $SYMLINK_TX
	fi

	# Check and symlink MariaDB ColumnStore admin CLI
	[ -f $SYMLINK_AX ] && return
	find_in_dir "$UM_PREFIX/bin" "mcsadmin"
	[ $FOUND -eq 0 ] && error "Unable to find MariaDB ColumnStore admin CLI binary in $UM_PREFIX/bin"
	ln -s "$UM_PREFIX/bin/mcsadmin" $SYMLINK_AX
}

symlinks_maxscale() {
	# Skip if exists
	[ -f $SYMLINK_MAXSCALE ] && return

	ln -s /usr/bin/maxctrl $SYMLINK_MAXSCALE
}

create_symlinks() {
	case $NODE_TYPE in
		tx)
			symlinks_tx
			;;
		um)
			symlinks_um
			;;
		maxscale)
			symlinks_maxscale
			;;
	esac

	# Check if we need to symlink zabbix-mariadb.sh and zabbix-maxscale.sh because RPM will install it /usr/bin, but config expects them in /usr/local/bin
	[ ! -e /usr/local/bin/zabbix-mariadb.sh ] && [ -e /usr/bin/zabbix-mariadb.sh ] && ln -s /usr/bin/zabbix-mariadb.sh /usr/local/bin/zabbix-mariadb.sh
	[ ! -e /usr/local/bin/zabbix-maxscale.sh ] && [ -e /usr/bin/zabbix-maxscale.sh ] && ln -s /usr/bin/zabbix-maxscale.sh /usr/local/bin/zabbix-maxscale.sh
}

# Main entry point
detect_node
create_symlinks

