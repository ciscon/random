#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

quakestat -qwm master.quakeservers.net > /tmp/quakeservers
quakestat -qwm master.quakeservers.net >> /tmp/quakeservers

server=""
port=""

declare -A admins

output=$(for both in $(awk -F'[ :]' '{print $3 , $4}' /tmp/quakeservers);do 
        if [ -z $server ];then
            server=$both
            continue
        fi
        if [ -z $port ];then
            port=$both
        fi
        if [ ! -z "$server" ] && [ ! -z "$port" ];then
            (
                output=$(echo -e "\xff\xff\xff\xffstatus 23" | nc -w 5 -u $server $port 2>/dev/null| strings) 
                admin=$(echo "$output"|awk -F'admin' '{print $2}'|awk -F'\' '{print $2}')
                host=$(echo "$output"|awk -F'hostname' '{print $2}'|awk -F'\' '{print $2}')
                version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
                if [ ! -z "$admin" ];then
                    echo -e "$admin\t$version\t$host\t$server"|tr -d "\n"
                    echo
                fi
            )&
            server=""
            port=""
        fi
        sleep .01
    done)

wait

while read -r line; do

    adminfull=$(echo -n "$line" | cut -f1 -d$'\t')

    adminemail=$(echo "$adminfull"|awk -F '[<>]' '{print $2}')
    admin=$(echo "$adminfull"|awk -F '[<>]' '{print $1}'|awk '{$1=$1};1')

    if [ -z "$admin" ];then
        admin="$adminemail"
    fi
    if [ ! -z "$adminemail" ];then
        key="$adminemail"
    else
        key="$admin"
    fi

    if [ ! -z "$key" ];then
        version=$(echo -n "$line" | cut -f2 -d$'\t')
        host=$(echo -n "$line" | cut -f3 -d$'\t')
        server=$(echo -n "$line" | cut -f4 -d$'\t')
        admins[$key]="$admin,$adminemail,$version,$server,$host"
    fi

done <<< "$output"

for adminline in "${!admins[@]}";do
    echo ${admins[$adminline]}
done
