# SUMMARY

This repository contains Zabbix templates for various MariaDB products, both stand-alone and clusters.

The page below contains not only configuration guidelines, but also a quick Zabbix installation reference with a focus on RHEL7 and derivatives. It is not intended as replacement to official Zabbix documentation; you are advised and encouraged to read it first. There you will also find a lot of information on older Zabbix and EL versions, other Linux distributions etc. 

# SYSTEM REQUIREMENTS

Server requirements: 

* Zabbix 3.0 or highder.

Agent requirements:

* Unix-like OS
* Bourne again shell, version 3 or better installed and available as `/bin/bash`
* GNU awk installed and available in the path as `awk`.
* Symlink support

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

# CONFIGURATION

## INITIAL SETUP

Log on to Zabbix web UI with the username `admin` and password `zabbix`.

Import MariaDB value mappings: go to `Administration -> General` and from top right drop-down, select `Value mapping`. Click `Import` in the top right corner and select the file, then click `Import`.

Import MariaDB monitoring templates: go to `Configuration -> Templates`. Click `Import` in the top right corner and select the file, then click `Import`.

## UPGRADING TEMPLATES

To import an updated set of templates, follow the instructions for installing templates above. Updated elements will automatically replace old ones and new ones will automatically be created. A set of checkboxes on the import screens gives you fine-grain control. 

## AVAILABLE TEMPLATES

The following templates are provided in the set:

* MariaDB Server: monitors common parameters from a MariaDB server. Applies to stand-alone servers, Galera cluster nodes, Master cluster nodes, Slave cluster nodes and User Module nodes.
* MariaDB TX Master: monitors specific metrics for a Master node in a Master-Slave cluster.
* MariaDB TX Slave: monitors specific metrics for a Slave node in a Master-Slave cluster.
* MariaDB TX Galera: monitors specific metrics for a node in a Galera cluster.
* MariaDB AX UM: monitors specific metrics for a User Module in an AX cluster.
* MariaDB AX PM: monitors specific metrics for a Performance Module in an AX cluster.
* MariaDB AX Group: monitors a group of UM/PM nodes that comprise an AX cluster.  
* MariaDB MaxScale: monitors specific metrics for a MaxScale instance.

See [templates/README.md](templates/README.md) for full description of each template and for tunables they contain.

## ASSIGNING TEMPLATES TO HOSTS

Each host should be assigned two templates.

The first template to assign is always the OS monitoring template. Zabbix comes with ready-to-use templates for Linux and Windows. 

The second template depends on its role:

* Stand-alone MariaDB server: MariaDB Server template.
* MaxScale node: MariaDB MaxScale template.
* Master node of a Master-Slave cluster: MariaDB TX Master template.
* Each Slave node of a Master-Slave cluster: MariaDB TX Slave template.
* Each node of a Galera cluster: MariaDB TX Galera template.
* Each User Module node of an AX (or just ColumnStore) cluster: MariaDB AX UM template.
* Each Performance Module node of an AX (or just ColumnStore) cluster: MariaDB AX PM template.

Notes: 

* In the case of a single-server ColumnStore installation (i.e. both the UM and PM inside the same OS), then assign both the MariaDB AX UM template and MariaDB AX PM template to this server.
* In case of multiple PM nodes in one ColumnStore cluster, do note that the `controllernode` process only runs on one of these nodes and that the `ProcMgr` process runs only on two of the PM nodes. This means that if you have more than one PM, you will get an alarm for `controllernode` process being down on all nodes but one and if you have more than two PM nodes, you will get an alarm for `ProcMgr` process being down on all but two. See the ColumnStore GRoup Template section in [templates/README.md](templates/README.md) on how to avoid these unnecessary alarms.

## PASSIVE AND ACTIVE CHECKS

The default mode for all items in these Zabbix templates is to use _passive checks_, i.e. the Zabbix server polls each Zabbix over TCP (default port is 10050). 

Al alternative to this is to use _active checks_ when the Zabbix client will push monitoring data to the Zabbix server. The default TCP port on Zabbix server is 10051 and must be reachable by the Zabbix agent. Check type (passive or active) is defined on per-item level. To switch to active checks: 

* In Zabbix UI, go to `Configuration -> Templates` and click `Items` for the desired template. Select desired item(s) and click `Mass update`. Check the checkbox labelled `Type` and select `Zabbix agent (active)`. Click `Save`.
* Edit the Zabbix agent configuration file `/etc/zabbix/zabbix_agentd.conf` and set the value of `ServerActive` to the address of the Zabbix server. Restart the Zabbix agent with `systemctl restart zabix-agent`.

## EMAIL NOTIFICATIONS

To enable notifications over email:
* Go to `Administration -> Users`, click the `Admin` user, then go to `Media` tab. Click `Add` and fill in the desired email address, then click `Add`.
* Go to `Administration -> Media types`, click on `Email` and change settings as necessary.
* Go to `Configuration -> Actions` and on the row named `Report problems...` click the link `Disabled` in the `Status` column to enable the reporting (status should change to `Enabled`).

To adjust the email template used for notifications (e.g., for automatic parsing), go to `Configuration -> Actions` and click the row named `Report problems...`, then modify the template and save it.

## AUTOMATIC TICKETS FROM EMAILS

### LEVEL MAPPING

MariaDB Zabbix templates use three trigger levels to denote how severe the impact of an event: `Warning`, `Average`, `High`. They correspond to S3, S2, S1 levels as follows:

* Warning -> S3
* Average -> S2
* High -> S1

You probably want to adjust the email template and parser to enable automatic creation of tickets with appropriate severity level.

### OPENING AND CLOSING

Zabbix will send two emails for each event, one when a trigger goes up and one when it goes down. This can be used to automatically open a ticket when a trigger goes up and then either close it or change its status when a trigger goes down. 

Both emails will contain the same event ID which can be used to correlate them and find appropriate ticket to close/amend when a trigger goes down.

