# Zabbix scripts and configurations for MariaDB

Summary: Zabbix scripts and configurations for MariaDB
Name: mariadb-zabbix
Version: %{_mdb_version}
%if "%{?dist:%{dist}}%{!?dist:0}" == ".rel"
Release: %{_mdb_release}%{?dist}.el%{rhel}
%else
Release: 0.%{_mdb_release}%{?dist}.el%{rhel}
%endif
Vendor: MariaDB
URL: http://www.mariadb.com
Packager: MariaDB <assen.totin@mariadb.com>
Group: MariaDB
License: Proprietary
BuildArch: x86_64
Requires: zabbix-agent

%description
Zabbix scripts and configurations for MariaDB

%prep

%build

%install

mkdir -p $RPM_BUILD_ROOT/etc/zabbix
cp -r ${RPM_SOURCE_DIR}/zabbix_agentd.d $RPM_BUILD_ROOT/etc/zabbix

mkdir -p $RPM_BUILD_ROOT/etc/zabbix/selinux
cp -r ${RPM_SOURCE_DIR}/selinux/*.pp $RPM_BUILD_ROOT/etc/zabbix/selinux

mkdir -p $RPM_BUILD_ROOT/etc/sudoers.d
cp -r ${RPM_SOURCE_DIR}/sudoers.d $RPM_BUILD_ROOT/etc

mkdir -p $RPM_BUILD_ROOT/usr
cp -r ${RPM_SOURCE_DIR}/bin $RPM_BUILD_ROOT/usr

mkdir -p $RPM_BUILD_ROOT/var/lib/zabbix
cp -r ${RPM_SOURCE_DIR}/conf/my.cnf $RPM_BUILD_ROOT/var/lib/zabbix/.my.cnf

%clean
rm -rf $RPM_BUILD_ROOT $RPM_BUILD_DIR

%files
%defattr(-, root, root)
/etc/zabbix/zabbix_agentd.d/*
/etc/zabbix/selinux
%attr(640,root,root) /etc/sudoers.d/*
%attr(755,root,root) /usr/bin/*
%dir /var/lib/zabbix
%attr(600,zabbix,root) /var/lib/zabbix/.my.cnf

%pre

%post
if [ $1 = 1 ]; then
	# Detect node type and create symlinks
	/usr/bin/zabbix-mariadb-symlinks.sh

	# Update Zabbix config to allow longer-running requests
	sed -i 's/^.*Timeout=.*/Timeout=30/' /etc/zabbix/zabbix_agentd.conf

	# Enable zabbix-agent service
	systemctl enable zabbix-agent

	# Allow inbound TCP if firewalld is running
	systemctl status firewalld >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		firewall-cmd --permanent --add-port 10050/tcp
		firewall-cmd --add-port 10050/tcp
	fi
fi

# Update SELinux policices
selinuxenabled
if [ $? -eq 0 ] ; then
	semodule -i /etc/zabbix/selinux/zabbix-mariadb.pp
fi

systemctl restart zabbix-agent

%preun

%postun

# NB: Changelog records the changes in this spec file. For changes in the packaged product, use the ChangeLog file.
%changelog
* Wed Oct 17 2018 MariaDB <assen.totin@mariadb.com>
- Release 0.0.1

