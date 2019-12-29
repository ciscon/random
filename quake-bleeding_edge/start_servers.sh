#!/bin/bash

quakepath="/opt/quake-bleeding"
cd "$quakepath"
scriptbase="quake_port"
portnum="$1"
port="${scriptbase}${portnum}.sh"
name="quake_bleeding-${portnum}"

if [ ! -z "$port" ];then

	if [ $(id -u ) != 1000 ];then
		su -c "screen -dmS $name $quakepath/run/$port" ciscon > /dev/null &
	else
		screen -dmS $name $quakepath/run/$port > /dev/null &
	fi
	echo "Started port $portnum"

else
	exit 1
fi
