#!/bin/bash
# Version 1.0

CONF=$1
source $CONF

echo "<?xml version=\"10.0\" encoding=\"UTF-8\" ?><prtg>"
for DEVICE in  "${DEVICES[@]}"
do
IFS="|" read DEVRESULTID RESULTID CONFDEVICEID STATUS DEVICENAME TIMESTART TIMEEND BYTES  <<< `sqlite3 /volume1/@ActiveBackup/activity.db "select * from device_result_table where device_name like '$DEVICE'" | tail -1`

ACTTIME=`date +%s`
if [ $TIMESTART == 0 ]
  then
RUNTIME=$TIMESTART
  else
RUNTIME=$(($TIMEEND - $TIMESTART))
fi
LASTRUN=$(($ACTTIME - $TIMEEND))

echo "<result><channel>$DEVICE: Last Backup</channel><value>$STATUS</value><ValueLookup>prtg.standardlookups.nas.abstatus</ValueLookup></result><result><channel>$DEVICE: Duration</channel><value>$RUNTIME</value><unit>TimeSeconds</unit></result><result><channel>$DEVICE: Time passed</channel><value>$LASTRUN</value><unit>TimeSeconds</unit><LimitMode>1</LimitMode><LimitMaxWarning>129600</LimitMaxWarning><LimitMaxError>216000</LimitMaxError></result><result><channel>$DEVICE: Data transferred</channel><value>$BYTES</value><unit>BytesDisk</unit><VolumeSize>GigaByte</VolumeSize></result>"
done
echo "<text>Devices: ${DEVICES[@]}</text></prtg>"
exit