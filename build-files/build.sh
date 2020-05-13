#!/bin/bash
#
# This script will build something
# Requires build-common.sh

# Package-specific constants
RPM_PACKAGE="mariadb-zabbix"
#ARCH="noarch"

# Find build-common.sh and source it
CURR_DIR=`pwd`
PROJECT_DIR=`dirname $CURR_DIR`
if [ -e /usr/libexec/mammothdb/build-server ] ; then
	BUILD_SERVER_DIR=/usr/libexec/mammothdb/build-server
	source $BUILD_SERVER_DIR/build-server/build-common.sh
else
	echo "ERROR: Unable to find build-common.sh"
	exit 1;
fi

# Call the common entry point
build_common $@

# Check out proper version
git_checkout

# Go to checkout dir
pushd $CHECKOUT_DIR

# Build SELinux module
cd selinux
checkmodule -M -m -o zabbix-mariadb.mod zabbix-mariadb.te
semodule_package -o zabbix-mariadb.pp -m zabbix-mariadb.mod
cd ..

# Copy files
cp -r $CHECKOUT_DIR/bin $RPM_HOME/SOURCES
cp -r $CHECKOUT_DIR/conf $RPM_HOME/SOURCES
cp -r $CHECKOUT_DIR/selinux $RPM_HOME/SOURCES
cp -r $CHECKOUT_DIR/sudoers.d $RPM_HOME/SOURCES
cp -r $CHECKOUT_DIR/templates $RPM_HOME/SOURCES
cp -r $CHECKOUT_DIR/zabbix_agentd.d $RPM_HOME/SOURCES

# Copy the appropriate spec file for the build
copy_spec_file

# Build the RPM and SRPM
build_rpms

popd

# Declare we're good
happy_end

