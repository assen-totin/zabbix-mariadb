# SUMMARY

This doc contains a quick Zabbix installation reference with a focus on RHEL7 and derivatives. It is not intended as replacement to official Zabbix documentation; you are advised and encouraged to read it first. There you will also find a lot of information on older Zabbix and EL versions, other Linux distributions etc. 

# SERVER INSTALLATION

If you plan to run a production Zabbix server for a longer time, consider switching to partitioned database to avoid issues with database housekeeping (https://zabbix.org/wiki/Docs/howto/mysql_partition).

## BACKEND

For true RHEL only, enable the "Optional" repository (skip for CentOS, Scientific Linux and other clones).

```yum-config-manager --enable rhel-7-server-optional-rpms```

Add the Zabbix repository

```rpm -ivh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm```

Install server and frontend with MariaDB as DB engine. This will also pull MariaDB, Apache and PHP for you.

```yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent```

Create database (adjust host if using remote MariaDB)

```
CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL PRIVILEGES ON zabbix.* to zabbix@localhost IDENTIFIED BY 'password';
```

Import database schema (add host if using remote MariaDB)

```zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p zabbix```

Edit `/etc/zabbix/zabbix_server.conf` and set credentials (plus host, if using remote MariaDB):

```
DBHost=localhost
DBPassword=<password>
```

If using SELinux on the server, update its configuration to allow web service to connect to Zabbix:

```setsebool -P httpd_can_connect_zabbix on```

Enable and start service

```
systemctl enable zabbix-agent
systemctl start zabbix-agent
systemctl enable zabbix-server
systemctl start zabbix-server
```

## FRONTEND

Edit the Zabbix frontend virtul host in `/etc/httpd/conf.d/zabbix.conf` and set the timezone in PHP settings. 

Enable and start web service

```
systemctl enable httpd
systemctl start httpd
```

Point your browser to `/zabbix` on the web server and follow the on-screen instructions.  In particular, re-enter the database configuration. Leave the Zabbix TCP port at `10051` if you have not changed it. 

# AGENT INSTALLATION

## PREPARATION

For true RHEL only, enable the "Optional" repository (skip for CentOS, Scientific Linux and other clones).

```yum-config-manager --enable rhel-7-server-optional-rpms```

Add the Zabbix repository

```rpm -ivh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm```

You can install the client side from a pre-built package or manually.

## PRE-BUILT PACKAGES

If you have access to the pre-built package `mariadb-zabbix` (e.g., RPM), then install it. It will install the Zabbix agent and make most of the necessary configurations. 

If the local `root` user has a password, edit the `/var/lib/zabbix/.my.cnf` file and add the password there.

Set the address of the Zabbix server in the agent configuration `/etc/zabbix/zabbix_agentd.conf`:

```Server=A.B.C.D```

Restart the Zabbix agent:

```systemctl restart zabbix-agent```

## MANUAL INSTALLATION

Install the agent

```yum install -y zabbix-agent```

Place MariaDB agent configuration file in `/etc/zabbix/zabbix_agentd.d/`.

Place MariaDB helper scripts in `/usr/local/bin` and make them executable.

On AX nodes, place the sudo configuration file in `/etc/sudoers.d`

On stand-alone servers, Master nodes, Slave nodes, Galera nodes and UM nodes, create a config directory containing a config file named `.my.cnf`, then add the local `root` user and its password to it and set proper permissions:

```mkdir -p /var/lib/zabbix```

```
[client]
user=root
password=password
```

```
chown zabbix /var/lib/zabbix/.my.cnf
chmod 600 /var/lib/zabbix/.my.cnf
```

Create symlinks to common CLI programs. You can either upload and run `zabbix-mariadb-symlinks.sh` or do it manually :

* For stand-alone MariaDB, Master nodes, Slave nodes and Galera nodes:

```ln -s /usr/bin/mysql /usr/local/bin/zabbix-mariadb```

* For AX UM nodes:
```
ln -s /usr/local/mariadb/columnstore/mysql/bin/mysql /usr/local/bin/mariadb-zabbix
ln -s /usr/local/mariadb/columnstore/bin/mcsadmin /usr/local/bin/zabbix-mcsadmin

```

Set the address of the Zabbix server in the agent configurtion `/etc/zabbix/zabbix_agentd.conf`; also increase the execution timeout:

```Server=A.B.C.D```

```Timeout=30```

If firewall is enabled on the client, permit TCP port 10050 from the Zabbix server:

```
firewall-cmd --permanent --add-port 10050/tcp
firewall-cmd --add-port 10050/tcp
```

If you have SELinux enabled, create a directory `/etc/zabbix/selinux` and copy the policy template file to it, then compile and load it:

```
checkmodule -M -m -o zabbix-mariadb.mod zabbix-mariadb.te
semodule_package -o zabbix-mariadb.pp -m zabbix-mariadb.mod
semodule -i zabbix-mariadb.pp

```

Enable and start service

```
systemctl enable zabbix-agent
systemctl start zabbix-agent
```

## SECURITY CONSIDERATIONS

The agent setup as described above uses the all-powerfull `root` user to access the information on the database. It is a better practice to use a dedicated user with a limited set of permissions. You can create a dedicated user like this:

```
CREATE USER 'zabbixmonitor'@'localhost' IDENTIFIED BY 'password';
GRANT PROCESS, SHOW DATABASES, REPLICATION CLIENT ON *.* TO 'zabbixmonitor'@'localhost';
GRANT SELECT ON *.* TO 'zabbixmonitor'@'localhost';
```

If you do not plan to use the database discovery and size calculation feature, you can further reduce the permissions by replacing the last line with a more restricted one: 

```
GRANT SELECT ON mysql.user TO 'zabbixmonitor'@'localhost’;
```

Once the user is created, put the username and its password in `/var/lib/zabbix/.my.cnf`


