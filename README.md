# nas_ab_status
Bash script for PRTG by Paessler to monitoring status of device backup in Synology Active Backup for Business

The sensor will show the status of the last backup, how many data were transferred, the duration and the time passed since the laste backup. nas_ab_status_m.sh is for multiple devices in one sensor.

Sensor has to be created in PRTG on your Synology device.

Sensor tested on DS 918+

### Prerequisites

Be sure you have set correct logon values for SSH in your device.

I personally use "Login via private key" with an user especially for monitoring which also may use sudo for this script without a password.

![Screenshot1](https://github.com/WAdama/nas_ab_status/blob/master/images/ssh_settings.png)

**HINT:** Since DSM 6.2.2 for SSH access the user has to be member of the local Administrators group on your Synology NAS.

### Installing

Place the script to /var/prtg/scriptsxml on your Synology NAS and make it executable. (You may have to create this directory structure because PRTG expects the script here.)

```
wget https://raw.githubusercontent.com/WAdama/nas_ab_status/master/nas_ab_status.sh
or
wget https://raw.githubusercontent.com/WAdama/nas_ab_status/master/nas_ab_status_m.sh
chmod +x nas_ab_status(_m).sh
```

On your PRTG system place the file prtg.standardlookups.nas.abstatus.ovl in *INSTALLDIR\PRTG Network Monitor\lookups\custom* and refresh it under **System Administration / Administrative Tools**

In PRTG create under your device which represents your Synology a SSH custom advanced senor.

Choose under "Script" this script and enter under "Parameters" the name of the device (PC or VM) backed up in Active Backup for Business you want to monitor: e.g. Server1 or VM1.

![Screenshot1](https://github.com/WAdama/nas_ab_status/blob/master/images/nas_ab_status.png)

For the multiple device sensor create a conf file in your Synology's file system.

The configuration file must contain the following entry according to your devices:

```
DEVICES=(Device1 VM1 Server1 Server2)
```
Instead of the device name in "Parameters" enter path and name of config file.

This script will set default values for limits in the "Time Passed" channel:

Upper warning limit: 36 h (129600 s)

Upper error limit: 60 h (216000 s)

![Screenshot1](https://github.com/WAdama/nas_ab_status/blob/master/images/nas_ab_status_sensor.png)
