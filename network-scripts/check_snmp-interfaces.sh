#!/bin/bash

HOST="$1"
COMMUNITY="$2"
INTS="$3"

IFS=,
for int in $INTS;do
	output=$(snmpget -t 5 -r 1 -Oqv -v 2c -c $COMMUNITY $HOST 1.3.6.1.2.1.2.2.1.8.${int} 2>&1)
	if [ "1" != "$output" ];then
		echo "interface $int is down!  error output: $(echo $output|tr -d '\n')"
		exit 2
	fi
done

echo "all interfaces up"
exit 0
