#!/bin/bash
# Version 1.0.3

DEVICE=$1
IFS="|" read RESULTID STATUS DEVICEID DEVICENAME BYTES  <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select result_id,status,config_device_id,device_name,transfered_bytes from device_result_table where device_name like '$DEVICE' OR config_device_id LIKE '$DEVICE' ORDER BY result_id DESC LIMIT 1"`
IFS="|" read TASKID  <<< `sqlite3 /volume1/@ActiveBackup/config.db "select task_id from backup_task_device where device_id like '$DEVICEID'"`
IFS="|" read LOGID TIMESTART  <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select log_id,log_time from log_table where task_id = '$TASKID' and log_type = '1101' ORDER BY log_time DESC LIMIT 1"`
IFS="|" read TIMEEND  <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select log_time from log_table where task_id = '$TASKID' and log_id > $LOGID and result_id = '$RESULTID' ORDER BY log_time DESC LIMIT 1"`
if [ -z "$TIMEEND" ] || [ $TIMEEND -lt $TIMESTART ]
	then 
	TIMEEND=$TIMESTART
fi
ACTTIME=`date +%s`
RUNTIME=$(($TIMEEND - $TIMESTART))
LASTRUN=$(($ACTTIME - $TIMESTART))

echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg><result><channel>Last Backup</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>Time passed</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
echo "<text>Device: $DEVICENAME (DeviceID: $DEVICEID)</text></prtg>"
exit
