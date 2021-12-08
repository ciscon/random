#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

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
                output=$(echo -e "\xff\xff\xff\xffstatus 23" | nc -w 5 -u $server $port 2>/dev/null|head -n1|strings) 
                host=$(echo "$output"|awk -F'hostname' '{print $2}'|awk -F'\' '{print $2}')
                version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
				if [ ! -z "$host" ];then
					echo "$host | $server | $port | $version"
				fi
            )&
            server=""
            port=""
        fi
        sleep .01
    done

wait
