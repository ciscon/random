#!/bin/bash

HOSTNAME="http://localhost"
PASSWORD="yourpassword"
TIMEOUT=5

if hash notify-send >/dev/null 2>&1;then
	ECHO=notify-send
else
	ECHO=echo
fi

if [ -z "$1" ];then
	$ECHO "no argument, exiting"
	exit 1
else
	magnet_link=$1
fi

auth_req=$(
	curl -f -s --cookie-jar /tmp/deluge.cookies "${HOSTNAME}/json" -H 'accept: */*' -H 'content-type: application/json' --data-raw '{"method":"auth.login","params":["'${PASSWORD}'"],"id":1}' --max-time $TIMEOUT 
2>&1)
if [ $? -ne 0 ] || [ -z "$auth_req" ];then
	$ECHO "auth error"
	exit 2
fi

magnet_req=$(
	curl -f -s -b /tmp/deluge.cookies "${HOSTNAME}/json" -H 'accept: */*' -H 'content-type: application/json' --data-raw '{"method":"web.add_torrents","params":[[{"path":"'${magnet_link}'","options":{"file_priorities":[],"add_paused":false,"sequential_download":false,"pre_allocate_storage":true }}]],"id":2}' --max-time $TIMEOUT 
2>&1)
if [ $? -ne 0 ] || [ -z "$magnet_req" ];then
	$ECHO "add torrent error"
	$ECHO "$magnet_req"
	exit 3
fi

$ECHO "torrent added successfully"

exit 0
