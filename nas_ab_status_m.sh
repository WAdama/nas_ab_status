#!/bin/bash
# Version 1.0.12

source "$1"
DEVICES=( "${DEVICES[@]^^}" )
TASK=${TASK^^}
echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg>"
for DEVICE in "${DEVICES[@]}"
do
DEVICEID=$(sqlite3 /volume1/@ActiveBackup/config.db "select device_id from device_table where host_name like '%$DEVICE%'")
TASKID=$(sqlite3 /volume1/@ActiveBackup/config.db "select task_id from backup_task_device where device_id like '$DEVICEID'")
SCHEDULED=$(sqlite3 /volume1/@ActiveBackup/config.db "select sched_content from task_table where task_id like '$TASKID'" | jq .schedule_setting_type)
RESULTID=$(sqlite3 /volume1/@ActiveBackup/activity.db "select result_id from result_table where task_id like '$TASKID' AND task_config like '%$DEVICE%' AND job_action = 1 ORDER BY result_id DESC LIMIT 1")
IFS="|" read -r STATUS DEVICENAME BYTES TIMESTART TIMEEND <<< "$(sqlite3 /volume1/@ActiveBackup/activity.db "select status,device_name,transfered_bytes,time_start,time_end from device_result_table where result_id like '$RESULTID'")"
SPEED=$(sqlite3 /volume1/@ActiveBackup/activity.db "select other_params from result_detail_table where result_id like '$RESULTID' AND log_type like '1111'" | jq -r .speed)
if [ -z "$RESULTID" ] 
then
	STATUS=0
	DEVICENAME=$DEVICE
	BYTES=0
fi
if [ -z "$DEVICENAME" ]
then
	STATUS=0
	DEVICENAME=$DEVICE
	BYTES=0
fi
ACTTIME=$(date +%s)
if [ -z "$TIMEEND" ] || [ "$TIMEEND" -lt "$TIMESTART" ]
	then 
	TIMESTART=$ACTTIME
	TIMEEND=$ACTTIME
fi
if [ "$TIMESTART" -eq 0 ]
then
	RUNTIME=0
	LASTRUN=0
else
	RUNTIME=$(("$TIMEEND"-"$TIMESTART"))
	LASTRUN=$(("$ACTTIME"-"$TIMESTART"))
fi
echo "<result><channel>$DEVICENAME: Status</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>$DEVICENAME: Job Scheduled</channel><value>$SCHEDULED</value><ValueLookup>prtg.standardlookups.nas.abstatus.scheduled</ValueLookup><ShowChart>0</ShowChart></result><result><channel>$DEVICENAME: Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>$DEVICENAME: Last Job Run</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>$DEVICENAME: Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result><result><channel>$DEVICENAME: Speed</channel><value>${SPEED%%\ MB/s}</value><unit>Custom</unit><customunit>MB/s</customunit><Float>1</Float></result>"
done
echo "<text>Task: $TASK / Device(s): $(echo "${DEVICES[@]}" | awk -v OFS=" / " '{$1=$1;print}')</text></prtg>"
exit
