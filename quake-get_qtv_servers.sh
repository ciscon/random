#!/bin/bash
timeout=30

echo > /tmp/quakeservers.1
echo > /tmp/quakeservers
quakestat -timeout $timeout -maxsim 100 -qwm qwmaster.fodquake.net|strings|grep -v 'no response' >> /tmp/quakeservers 2>/dev/null&
quakestat -timeout $timeout -maxsim 100 -qwm master.quakeservers.net|strings|grep -v 'no response' >> /tmp/quakeservers 2>/dev/null&

wait

server=""
port=""
for both in $(awk -F'[ :]' '{print $3 , $4}' /tmp/quakeservers|sort -u);do
if [ -z "$server" ];then
    server=$both
    continue
fi
if [ -z "$port" ];then
    port=$both
fi
if [ ! -z "$server" ] && [ ! -z "$port" ];then
    (
    output=$(echo -e "\xff\xff\xff\xffstatus 32" | nc -w $timeout -u $server $port 2>/dev/null| strings)
    if [ ! -z "$output" ];then
        if echo "$output"|grep -e '^nqtv' >/dev/null 2>&1;then
            echo "$server" >> /tmp/quakeservers.1
        fi
    fi
    )&
    (
    output=$(echo -e "\xff\xff\xff\xffstatus 25" | nc -w $timeout -u $server $port 2>/dev/null| strings)
    version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
    if [ ! -z "$version" ];then
        if echo "$version"|grep -e '^QTV' >/dev/null 2>&1;then
            output="$server"
            if [ "$port" != "28000" ];then
                output="$server $port"
            fi
            echo "$output" >> /tmp/quakeservers.1
        fi
    fi
    )&
    server=""
    port=""
fi
done

wait

for server in $(sort -u /tmp/quakeservers.1);do
    (
    if [ "$(echo -e 'GET /\n'|nc -w $timeout $server 28000 2>/dev/null|grep -c 'nowplaying')" == "1" ];then
        echo "$server"
    fi
    )&
done

wait
