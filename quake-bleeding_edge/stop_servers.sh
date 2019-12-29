#!/bin/bash

quakepath="/opt/quake-bleeding"
cd "$quakepath"
scriptbase="quake_port"
portnum="$1"
port="${scriptbase}${portnum}.sh"
name="quake_bleeding-${portnum}"

if [ ! -z "$port" ];then
	echo "Stopping port $portnum"

	pgrep -f "mvdsv -port $portnum"|xargs -r kill >/dev/null 2>&1
	sleep 1
	pgrep -f "mvdsv -port $portnum"|xargs -r kill -9 >/dev/null 2>&1
	sleep 1

	pgrep -f "SCREEN.*$name"|xargs -r kill -9 >/dev/null 2>&1

        echo "Stopped port $portnum"
else
	exit 1
fi
