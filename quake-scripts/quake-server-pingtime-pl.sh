#!/bin/bash
#test response time of qw server on given ports, output if there is no response or above rtt threshold

host=quakecon.miami.ultrav.us
ports="28501 28502"
rtt_threshold=10
sleeptime=1

while [ 1 ];do

  for port in $ports;do

    current=$(date +%s%N|cut -b1-13)
    rtt=$(
      echo -e "\xff\xff\xff\xffstatus 23"|nc -w $rtt_threshold -u $host $port|stdbuf -i0 -o0 -e0 strings| \
        while read -t 3 -r line;do

        rtt=$(echo "scale=100;$(date +%s%N|cut -b1-13)-${current}"|bc)
        echo "$rtt"
        break

      done
    )

    #no response?
    if [ -z "$rtt" ];then rtt=999;fi

    if [ $rtt -gt $rtt_threshold ];then
      echo "$(date) : $host $port rtt=$rtt"
    fi

    sleep $sleeptime

  done

done
