#!/bin/bash
# Version 1.0.1

DEVICE=$1
IFS="|" read DEVRESULTID RESULTID CONFDEVICEID STATUS DEVICENAME TIMESTART TIMEEND BYTES  <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select * from device_result_table where device_name like '$DEVICE'" | tail -1`

ACTTIME=`date +%s`
RUNTIME=$(($TIMEEND - $TIMESTART))
LASTRUN=$(($ACTTIME - $TIMESTART))

echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg><result><channel>Last Backup</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>Time passed</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
echo "<text>Device: $DEVICENAME</text></prtg>"
exit
