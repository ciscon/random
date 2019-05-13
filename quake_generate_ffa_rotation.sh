#!/bin/bash
# generate ffa map rotation using specified list in the following format:
#	mapname minplayers maxplayers

#shuffle map cycle?
shuffle=1

#map list
maps="ultrav
spinev2 3 14
shifter 3
aerowalk 0 14
dm2 3"


shuffle_com="cat"
if [ "$shuffle" -eq 1 ];then
	shuffle_com="shuf"
fi
newmaps=$(echo "$maps"|sort -u|$shuffle_com)

count=0

while read -r line; do
	map=""
	min=""
	max=""
	for part in $line;do
		if [ -z $map ];then
			map=$part
			continue
		fi
		if [ -z $min ];then
			min=$part
			continue
		fi
		if [ -z $max ];then
			max=$part
			continue
		fi
	done
	echo 'set k_ml_'$count' "'$map'"'
	if [ ! -z $min ] && [ $min -ne 0 ];then
		echo 'set k_ml_minp_'$count' "'$min'"'
	fi
	if [ ! -z $max ] && [ $max -ne 0 ];then
		echo 'set k_ml_maxp_'$count' "'$max'"'
	fi
	let count=count+1
done <<< "$newmaps"
