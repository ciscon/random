#!/bin/bash

quakepath="/opt/quake-bleeding"
cd "$quakepath"

for port in /opt/quake-bleeding/run/*;do
        port=$(basename $port)
        name="${port%.*}"
	portnum=$(echo "$name"|sed 's/[^0-9]*//g')

	echo "Stopping port $portnum"

	pgrep -f "mvdsv -port $portnum"|xargs -r kill >/dev/null 2>&1
	sleep 1
	pgrep -f "mvdsv -port $portnum"|xargs -r kill -9 >/dev/null 2>&1
	sleep 1

	pgrep -f "SCREEN.*$name"|xargs -r kill -9 >/dev/null 2>&1

        echo "Stopped port $portnum"
done
