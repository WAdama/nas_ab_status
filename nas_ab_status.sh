#!/bin/bash
# Version 3.0.0
# DB query realised with the help of https://github.com/r2evans, see also https://github.com/WAdama/nas_ab_status/issues/8
set -euo pipefail
TASK="${1:-}" || true
#Database locations
CONFIG="/volume1/@ActiveBackup/config.db"
ACTIVITY="/volume1/@ActiveBackup/activity.db"
SYSTEM="/volume1/@ActiveBackup/agent/system-db.sqlite"
#Functions
xml_escape() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
is_running() {
  local id="$1"
  printf '%s\n' "${RUNNING_IDS[@]}" | grep -qx "$id"
}
#Database searches
mapfile -t ALLDEVICES < <(
sqlite3 -readonly -list "$CONFIG" "ATTACH DATABASE '$ACTIVITY' AS activity;
WITH ranked_results AS (
    SELECT 
        dt.host_name,
        dt.device_id,
        tt.source_type,
        drt.status,
        rt.time_start,
        rt.time_end,
        drt.transfered_bytes,
        json_extract(rdt.other_params, '$.speed') AS speed,
        json_extract(tt.sched_content, '$.schedule_setting_type') AS scheduled,
        ROW_NUMBER() OVER (PARTITION BY dt.host_name ORDER BY rt.time_start DESC) AS rn
    FROM device_table dt
    LEFT JOIN backup_task_device btd ON dt.device_id = btd.device_id
    LEFT JOIN task_table tt ON tt.task_id = btd.task_id
    LEFT JOIN result_table rt ON rt.task_id = btd.task_id
    LEFT JOIN device_result_table drt ON rt.result_id = drt.result_id
    LEFT JOIN result_detail_table rdt ON rt.result_id = rdt.result_id
    WHERE (rt.job_action IS NULL OR rt.job_action = 1)
      AND rdt.log_type IN ('1111','1102')
      AND tt.task_name LIKE '$TASK'
)
SELECT
        host_name,
        device_id,
        source_type,
        status,
        time_start,
        time_end,
        transfered_bytes,
        speed,
        scheduled
FROM ranked_results
WHERE rn = 1;"
)
mapfile -t RUNNING_IDS < <(
  sqlite3 -readonly -list "$SYSTEM" "select device_id from running_task_table;"
)
#Processing data
echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg>"
for ONEDEVICE in "${ALLDEVICES[@]}"
do
  IFS="|" read -r DEVICENAME ID SOURCE STATUS TIMESTART TIMEEND BYTES SPEED SCHEDULED <<< "$ONEDEVICE"
  DEVICENAME=$(xml_escape <<< "${DEVICENAME%%.*}")
  SPEED=${SPEED// /}
  SPEED=$((${SPEED%%.*}*$(echo "$SPEED" | grep -oE 'GB|MB|KB|B' | sed 's/GB/1073741824/;s/MB/1048576/;s/KB/1024/;s/B/1/')))
  if [ -z "$DEVICENAME" ]
  then
    STATUS=0
    BYTES=0
  fi
  if is_running "$ID"; then
    STATUS=6
  fi
  ACTTIME=$(date +%s)
  if (( TIMESTART <= 0 || TIMEEND < TIMESTART )); then
    RUNTIME=0
    LASTRUN=0
  else
    RUNTIME=$(( TIMEEND - TIMESTART ))
    LASTRUN=$(( ACTTIME - TIMEEND ))
  fi
  echo "<result><channel>$DEVICENAME: Status</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup><ShowChart>0</ShowChart></result><result><channel>${DEVICENAME}: Job Scheduled</channel><value>$SCHEDULED</value><ValueLookup>prtg.standardlookups.nas.abstatus.scheduled</ValueLookup><ShowChart>0</ShowChart></result><result><channel>$DEVICENAME: Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>$DEVICENAME: Last Job Run</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>$DEVICENAME: Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
  if [ "$SOURCE" -ne "0" ]
  then
    echo "<result><channel>$DEVICENAME: Speed</channel><value>$SPEED</value><unit>SpeedNet</unit><Float>1</Float></result>"
  fi
done
echo "</prtg>"
exit 0
