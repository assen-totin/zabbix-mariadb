# TESTING TEMPLATES

Testing all the templates follows a similar workflow. You need a Zabbix server with the value mappings and templates imported. You need general knowledge of Zabbix web UI. 

Only Unix-like OS are supported as MariaDB hosts with RHEL-7 being the reference one. Alway first test on the reference OS and only when tests pass try alternative ones if desired. 

* Create a stand-alone MariaDB server or a cluster of the desired type. On each MariaDB host, install and configure Zabbix agent. See the main README for details.
* For each MariaDB host, create a separate host in Zabbix and assign it the approprate template. You ony assign one template to a host. See the main README for info on which template is intended for which node type.
* The data from MariaDB templates is grouped into Zabbix applications which name always starst with _MariaDB_. Check each template for actual application name(s). 
* Go to `Monitoing -> Latest Data`. In the host field, enter the Zabix name of the desired host and click `Apply`. Observe the data being loaded (the page will refresh automatically) and verify its presence and values.

Notes:

* Each item has a refresh interval (for most items it is 5 minutes, but for some is 1 hour). You may need to wait up to twice the refresh interval to get the first value loaded. See the item list in each template for each item's refresh interval.
* Certain items will only be created by the discovery mechanism, which also runs in predefined intervals. Check the discovery list in each template for each rule's run interval, then check the refresh interval for each item's prototype inside the discovery rule. In general, you must wait one run interval for the discovery to create the items and then one refresh interval for each item to obtain its first value.

# TESTING SELINUX POLICY

The SELinux policy applies to the host where the Zabbix agent runs. The host must run SELinux in enforcing mode. 

The policy is not applicable to MaxScale and UM/PM nodes as these require SELinux to be turned off. 

The SELinux policy must be installed on the monitored host before testing. See the main README for details. 

Once the policy has been loaded, add the host to Zabbix and assign it its appropriate template, then observe the values being loaded properly. You can observe the SELinxu audit log (usually `/var/log/audit.log`) to verify the policy is applied and used. If certain values do not load properly, check the same log for any DENY entries and report them.

