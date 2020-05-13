# SUMMARY

This repository contains Zabbix templates for various MariaDB products, both stand-alone and clusters (including the clustered ColumnStore engine and MaxScale load balancer).

See [Zabbix.md](Zabbix.md) for some quick installation instruction if you are not familiar with Zabbix.

See [templates/README.md](templates/README.md) for a detailed list of what these templates can monitor.

# SYSTEM REQUIREMENTS

Server requirements: 

* Zabbix 3.0 or highder.

Agent requirements:

* Unix-like OS
* Bourne again shell, version 3 or better installed and available as `/bin/bash`
* GNU awk installed and available in the path as `awk`.
* Symlink support

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

MariaDB Zabbix templates use three trigger levels to denote how severe the impact of an event: `Warning`, `Average`, `High`. You may use them tomap to desired levels in a ticketing system.

You probably want to adjust the email template and parser to enable automatic creation of tickets with appropriate severity level.

### OPENING AND CLOSING

Zabbix will send two emails for each event, one when a trigger goes up and one when it goes down. This can be used to automatically open a ticket when a trigger goes up and then either close it or change its status when a trigger goes down. 

Both emails will contain the same event ID which can be used to correlate them and find appropriate ticket to close/amend when a trigger goes down.

