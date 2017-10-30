#!/bin/bash -x

blah=0

while [ 1 ];do 
	blah1=$blah
	blah=$(cat /proc/interrupts |grep -i snd|tail -n1|awk '{print $2}')
	echo "${blah} - ${blah1}"|bc
	sleep 5
done

