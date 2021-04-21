#!/bin/bash
# Version 1.0.4

DEVICE=$1
TASK=$2
DEVICE=${DEVICE^^}
TASK=${TASK^^}
IFS="|" read RESULTID TASKID <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select result_id,task_id from result_table where task_name like '$TASK' AND task_config like '%$DEVICE%' AND job_action = 1 ORDER BY result_id DESC LIMIT 1"`
IFS="|" read STATUS DEVICENAME BYTES TIMESTART TIMEEND <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select status,device_name,transfered_bytes,time_start,time_end from device_result_table where result_id like '$RESULTID'"`
if [ -z "$RESULTID" ] 
then
	STATUS=0
	DEVICENAME=$DEVICE
	BYTES=0
fi
if [ -z "$DEVICENAME" ]
then
	STATUS=1
	DEVICENAME=$DEVICE
	BYTES=0
fi
ACTTIME=`date +%s`
if [ -z "$TIMEEND" ] || [ $TIMEEND -lt $TIMESTART ]
	then 
	TIMESTART=$ACTTIME
	TIMEEND=$ACTTIME
fi
if [ $TIMESTART -eq 0 ]
then
	RUNTIME=0
	LASTRUN=0
else
	RUNTIME=$(($TIMEEND - $TIMESTART))
	LASTRUN=$(($ACTTIME - $TIMESTART))
fi
echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg><result><channel>Last Backup</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>Time passed</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
echo "<text>Task $TASK: $DEVICENAME</text></prtg>"
exit
