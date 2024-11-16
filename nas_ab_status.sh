#!/bin/bash
# Version 2.0.1
# DB query realised with the help of https://github.com/r2evans, see also https://github.com/WAdama/nas_ab_status/issues/8

TASK=$1

CONFIG="/volume1/@ActiveBackup/config.db"
ACTIVITY="/volume1/@ActiveBackup/activity.db"

mapfile -t ALLDEVICES < <( sqlite3 -readonly -list $CONFIG "attach database '$ACTIVITY' as activity; 
select * from (
  select dt.host_name,tt.source_type,drt.status,rt.time_start,rt.time_end,drt.transfered_bytes,json_extract(rdt.other_params, '$.speed') as speed,json_extract(tt.sched_content, '$.schedule_setting_type') as scheduled, rank() over (partition by dt.host_name order by rt.time_start desc) as rn
  from device_table dt
    left join backup_task_device btd on dt.device_id = btd.device_id left join task_table tt on tt.task_id = btd.task_id left join result_table rt on rt.task_id = btd.task_id left join device_result_table drt on rt.result_id = drt.result_id left join result_detail_table rdt on rt.result_id = rdt.result_id left join log_table lt on rt.result_id = lt.result_id
  where (rt.job_action is null or rt.job_action = 1) and (rdt.log_type = '1111' or rdt.log_type = '1102') and (tt.task_name like '$TASK')
)
group by host_name having count (host_name) > 1" )
echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg>"
for ONEDEVICE in "${ALLDEVICES[@]}"
do
IFS="|" read -r DEVICENAME SOURCE STATUS TIMESTART TIMEEND BYTES SPEED SCHEDULED RANK <<< "$ONEDEVICE"
case $SPEED in
     *"GB/s"*) SPEED=$((${SPEED%%.*}*1073741824)) ;;
     *"MB/s"*) SPEED=$((${SPEED%%.*}*1048576)) ;;
     *"KB/s"*) SPEED=$((${SPEED%%.*}*1024)) ;;
     *"B/s"*) SPEED=${SPEED%%.*} ;;
esac
if [ -z "$DEVICENAME" ]
then
    STATUS=0
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
    LASTRUN=$(("$ACTTIME"-"$TIMEEND"))
fi
echo "<result><channel>${DEVICENAME%%.*}: Status</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>${DEVICENAME%%.*}: Job Scheduled</channel><value>$SCHEDULED</value><ValueLookup>prtg.standardlookups.nas.abstatus.scheduled</ValueLookup><ShowChart>0</ShowChart></result><result><channel>${DEVICENAME%%.*}: Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>${DEVICENAME%%.*}: Last Job Run</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>${DEVICENAME%%.*}: Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
if [ "$SOURCE" -ne "0" ]
then
echo "<result><channel>${DEVICENAME%%.*}: Speed</channel><value>$SPEED</value><unit>SpeedNet</unit><Float>1</Float></result>"
fi
done
echo "</prtg>"
exit
