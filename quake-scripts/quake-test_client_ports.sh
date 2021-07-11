#!/bin/bash

#uses: hping3, sudo, awk, sort

host=quakecon.miami.ultrav.us
port=28501
start=27000
stop=27500

#clientport scanner
for clientport in $(seq $start $stop);do echo -n "client port=$clientport ";echo -e "\xff\xff\xff\xffstatus 23"|sudo hping3 -2 $host -p $port -E /dev/stdin -d 10 -c 1 -s $clientport 2>/dev/null|grep --color=never 'rtt=';done|awk -F'[= ]' '{print $16,":",$3}'|sort -nr
