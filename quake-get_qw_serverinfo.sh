#!/bin/bash

quakestat -qwm master.quakeservers.net > /tmp/quakeservers
quakestat -qwm qwmaster.fodquake.net >> /tmp/quakeservers

server=""
port=""
for both in $(awk -F'[ :]' '{print $3 , $4}' /tmp/quakeservers);do 

	if [ -z $server ];then
		server=$both
		continue
	fi
	if [ -z $port ];then
		port=$both
	fi
	if [ ! -z "$server" ] && [ ! -z "$port" ];then
		(
		output=$(echo -e "\xff\xff\xff\xffstatus 1" | nc -w 5 -u $server $port | strings) 
		version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
		if [ ! -z "$version" ];then
			echo "$version - $server $port"|grep -e '^QTV'
		fi
		)&
		server=""
		port=""
		fi

done

wait
