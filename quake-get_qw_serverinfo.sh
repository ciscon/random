#!/bin/bash

quakestat -qwm master.quakeservers.net > /tmp/quakeservers
quakestat -qwm master.quakeservers.net >> /tmp/quakeservers

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
            output=$(echo -e "\xff\xff\xff\xffstatus 23" | nc -w 5 -u $server $port | strings) 
            admin=$(echo "$output"|awk -F'admin' '{print $2}'|awk -F'\' '{print $2}')
            host=$(echo "$output"|awk -F'hostname' '{print $2}'|awk -F'\' '{print $2}')
            version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
            if [ ! -z "$admin" ];then
                echo "$version - $host - $server $port - $admin"
            fi
        )&
        server=""
        port=""
    fi

done
