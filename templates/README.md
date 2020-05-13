Below is a list of all templates in this set together with a description what each template monitors. For triggers, the level of each trigger is also given.

# SERVER TEMPLATE

Included by: Master Node, Slave Node, Galera Node and UM Node templates. 

Can be used on stand-alone servers. 

Triggers:

* MariaDB instance cannot be connected: High
* Current connections count is over threshold (set in template or host): Average
* Current connections percentage is over threshold (set in template or host): Warning
* Long-living connections are present (time threshold set in template or host): Warning
* Failed connections percentage is over threshold (set in template or host): Warning
* Memory usage percent is over threshold (set in template or host) - Linux only, RSS: Average
* Server has users without password: Average
* Long-running query detected (time threshold set in template or host): Warning
* Slow query detected: Warning
* Number of running queries over threshold (set in template or host): Average

Other collected metrics:

* New connections per second
* Running queries per second
* Number of MariaDB processes running
* MariaDB memory usage (Linux only, RSS)
* MariaDB inbound and outbound traffic, kbps
* MariaDB service uptime
* SQL queries per second by query type (INSERT, UPDATE, SELECT, DELETE, BEGIN, COMMIT, ROLLBACK)
* Auto-discovery of databases
* Database data size (as reported by MariaDB engine)
* Database disk usage (as reported by OS; for local storage engines only, i.e. not for ColumnStore)

Graphs:

* MariaDB inbound and outbound traffic, kbps
* Concurrent connection and queries
* Connections and queries per second
* SQL operations per second

Macros (alarm thresholds):

* `{$MARIADB.SERVER.CONN.CURR.COUNT}` - the number of connections; default: 100; set to -1 to disable trigger
* `{$MARIADB.SERVER.CONN.CURR.PERCENT}` - the percent of allowed connections; default: 60; set to -1 to disable trigger
* `{$MARIADB.SERVER.CONN.FAIL.PERCENT}` - the percent of failed connections; default: 10; set to -1 to disable trigger
* `{$MARIADB.SERVER.MEMORY.PERCENT}` - the percent of RAM used by server; default: 60; set to -1 to disable trigger
* `{$MARIADB.SERVER.QUERY.CURR.COUNT}` - the number of concurrent queries; default: 100; set to -1 to disable trigger
* `{$MARIADB.SERVER.QUERY.CURR.TIME}` - the duration of the longest-running query in seconds; default: 60; set to -1 to disable trigger

Defaults can be overridden by defining the same macro with another value in any other templates that included this one, or in the host configuration.

TODO: 

* Error Log Entries (S2)

# MAXSCALE TEMPLATE

Triggers: 

* MaxScale process is not running: High
* Cannot connect to MaxScale SQL port: High
* Server cannot be connected: High

Graphs:

* MaxScale connections to service
* MaxScale connections to server

Macros:

* `{$MAXSCALE_PORT}` - the TCP port to connect to MaxScale; default: 3306

Defaults can be overridden by defining the same macro with another value in the host configuration.

# MASTER NODE TEMPLATE

Includes Server template.

No specific triggers.

Other collected metrics:

* Semi-sync master status

# SLAVE NODE TEMPLATE

Includes Server template.

Triggers:

* Node I/O thread not running: Average
* Node SQL thread not running: Average
* Node last SQL error number: Average
* Node lags behind master above threshold (set in template or host): Average

Other collected metrics:

* Semi-sync slave status

Macros (alarm thresholds):

* `{$MARIADB.TX.SLAVE.LAG}` - number of seconds the slave lags behind the master; default: 5; set to -1 to disable trigger

Defaults can be overridden by defining the same macro with another value in the host configuration.

# GALERA NODE TEMPLATE

Includes Server template.

Triggers:

* Cluster not ready: Average
* Cluster size changed: Warning
* Node local state changed: Average
* Node not connected: Average
* Node not ready: Average
* Node flow control "on" fraction is above threshold (set in template or host): Warning
* Node queue size send above threshold (set in template or host): Warning
* Node queue size receive above threshold (set in template or host): Warning

Macros (alarm thresholds):

* `{$MARIADB.TX.GALERA.FLOW}` - number of seconds since last check when the flow control has been "on"; default: 0.1; set to -1 to disable trigger
* `{$MARIADB.TX.GALERA.QUEUE.RECV}` - length of the receive queue; default: 10; set to -1 to disable trigger
* `{$MARIADB.TX.GALERA.QUEUE.SEND}` - length of the send queue; default: 10; set to -1 to disable trigger

Defaults can be overridden by defining the same macro with another value in the host configuration.

# UM NODE TEMPLATE

Includes Server template.

Triggers:

* Read-only mode alarm: High
* Process down alarm: High
* Module down alarm: High
* System down alarm: High
* Alarm is present: Average
* Process DDLProc is not running: High
* Process DMLProc is not running: High
* Process ExeMgr is not running: High
* Process ProcMon is not running: High
* Process ServerMonitor is not running: High
* Process workernode is not running: High

NB: Items/triggers for processes `ProcMon`, `ServerMonitor` and `workernode` are also part of the PM template as these processes are present on both UM and PM nodes. If both templates are applied to same host (e.g., for single-server installations of ColumnStore), items will appear twice - that is normal and expected. 

# PM NODE TEMPLATE

Triggers:

* Process controllernode is not running: High
* Process DecomSvr is not running: High (Disabled by default as it was only present in ColumnStore 1.0 and 1.1 series; enable it manually if you use such version.)
* Process PrimProc is not running: High
* Process ProcMgr is not running: High
* Process ProcMon is not running: High
* Process ServerMonitor is not running: High
* Process workernode is not running: High
* Process WriteEngineServ is not running: High

NB: Items/triggers for processes `ProcMon`, `ServerMonitor` and `workernode` are also part of the UM template as these processes are present on both UM and PM nodes. If both templates are applied to same host (e.g., for single-server installations of ColumnStore), items will appear twice - that is normal and expected. 

Macros:

* `{$MARIADB.AX.GRP.ENABLED}` - denotes whether a host group is used to track aggregate triggers for ColumnStore cluster; default: 0; for multi PM installations. declare this macro in each PM host that is a group member with a value of `1`.

# COLUMNSTORE GROUP TEMPLATE

Triggers:

* Process controllernode is not running on any node in the group: High
* Process ProcMgr is not running on any node in the group: High

NB: In case of multiple PM nodes in one ColumnStore cluster, do note that the `controllernode` process only runs on one of these nodes and that the `ProcMgr` process runs only on two of the PM nodes. This means that if you have more than one PM, you will get an alarm for `controllernode` process being down on all nodes but one and if you have more than two PM nodes, you will get an alarm for `ProcMgr` process being down on all but two. To avoid these unnecessary alarms: 
    * Create a new host group in Zabbix (e.g., named `MariaDB AX Cluster 1`).
    * Add all PM and UM nodes to this new group.
    * Edit each PM node and add a macro named `{$MARIADB.AX.GRP.ENABLED}` with value of `1`.
    * Do a full clone of the `MariaDB AX Group` template under a new name, e.g. `MariaDB AX Cluster 1`.
    * Edit the cloned template `MariaDB AX Cluster 1`; in each item edit the key and change the first parameter of the `grpsum` function to the name of the host group created above (e.g.,`MariaDB AX Cluster 1`; keep the group name in quotes).
    * Edit the UM node (or only one of the UM nodes, if there are several) and add to it the cloned template `MariaDB AX Cluster 1`. 

