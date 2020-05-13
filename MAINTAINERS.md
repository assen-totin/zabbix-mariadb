# SERVER SIDE

Zabbix has ready to use installers for many popular platforms. 

Importing the MariaDB Zabbix templates is easily done via the web interface (2 files to import only), so packaging them for automated installation is currently not seen as necessary. Should such need arise, Zabbix has a well-documented API which allows the import of value mappings and templates - hence scripting the import of a new version of templates should be trivial. Once this is done, wrapping the templates and the import script into a preferred package manager should also be easy.

# AGENT SIDE

The agent side installation consists of more steps and takes more time that the server side, so automation is more beneficial here. 

All steps, necessary to set up the Zabix agent side, are described in the main README. 

The following is provided as further help to maintainers:

* The script `bin/zabbix-mariadb-symlinks.sh` can be used to create the required symlinks to various CLI in /usr/local/bin where the template helper scripts expected them. The script will try to auto-detect node type and set symlinks accordingly; it will also try to find various CLI in popular locations, some of which are non-standard (like Red Hat's Software Collections). If the script is unable to detect the node type or find required CLI, it will report so. 
* For RPM packaging, a spec file is provided in `build-files/el7/rpm.spec`. It needs several constants to be defined externally, all their names starting with `_mdb_`; see inside the spec file for details. It also outlines which files go where, so can be used as a hint when preparing specifications for other package managers. 
* For those using MammothDB build server, a ready-to-use build job is provided in `build-files/build.sh`. It is coupled with the above spec file; just provide the usual input parameters on command line or configure a Jenkins job to run it. 









