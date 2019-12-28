#!/bin/bash 

quakepath="/opt/quake-bleeding"
cd "$quakepath"

anyrunning=0

for port in /opt/quake-bleeding/run/*;do
	portrunning=false
	port=$(basename $port)
        name="${port%.*}"
	portnum=$(echo "$name"|sed 's/[^0-9]*//g')
	if [ $(pgrep -c -f "mvdsv -port $portnum" 2>/dev/null) -eq 1 ];then
		anyrunning=1
		players=$(quakestat -raw ',' -qws localhost:$portnum|head -n1|awk -F',' '{print $6}')
		re='^[0-9]+$'
		if [[ $players =~ $re ]] ; then
			if [ $players -gt 0 ];then
				echo "Port $portnum is running with $players player(s) on it."
			else
				echo "Port $portnum is running with no players on it."
			fi
		fi
	else
		echo "Port $portnum is NOT running."
	fi
done

exit $anyrunning
