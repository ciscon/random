#!/bin/bash

quakepath="/opt/quake-bleeding"
cd "$quakepath"

for port in /opt/quake-bleeding/run/*;do
	port=$(basename $port)
	name="${port%.*}"
        portnum=$(echo "$name"|sed 's/[^0-9]*//g')
	if [ $(id -u ) != 1000 ];then
		su -c "screen -dmS $name $quakepath/run/$port" ciscon > /dev/null &
	else
		screen -dmS $name $quakepath/run/$port > /dev/null &
	fi
	echo "Started port $portnum"
done
