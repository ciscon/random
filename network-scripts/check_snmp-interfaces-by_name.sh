#!/bin/bash

HOST="$1"
COMMUNITY="$2"
INTS="$3"

#get names
output=$(snmpwalk -t 5 -r 1 -Oq -v 2c -c $COMMUNITY $HOST 1.3.6.1.2.1.31.1.1.1.1 2>/dev/null)

declare -A interfaces_array
numericre='^[0-9]+$'

while read int;do 
	read intname intid <<< $(echo "$int"|awk -F'[."]' '{print $(NF-1),$(NF-2)}')
	if [ ! -z "$intname" ] && [[ $intid =~ $numericre ]];then
		interfaces_array[$intname]=$intid
	fi
done <<< $(echo "$output")

IFS=,
for int in $INTS;do
	intid=${interfaces_array[$int]}
	if [ -z "$intid" ];then
		echo "could not find interface id for interface name $int!"
		exit 2
	fi
	output=$(snmpget -t 5 -r 1 -Oqv -v 2c -c $COMMUNITY $HOST 1.3.6.1.2.1.2.2.1.8.${intid} 2>&1)
	if [ "1" != "$output" ];then
		echo "interface $int is down!  error output: $(echo $output|tr -d '\n')"
		exit 2
	fi
done

echo "all interfaces up"
exit 0
