#!/bin/bash
#generate ffa map rotation using specified list in the following format:
#	mapname minplayers maxplayers

#shuffle map cycle?
shuffle=1

#this is our fallback map
firstmap="ultrav"

maps="
spinev2 3
shifter 3
ztndm5 2
burialb2 0 14
rwild 3
qwdm1 3
ztndm4 2
aerowalk 0 14
dm2 3
debello 3
ztndm2 4
p3a 2
a2 2
pkeg1
river 3
ztndm3
efdm8 3
rf2 2
subterfuge 2
spitfire 3
zen 3 10
ztndm6 3
trw 3
ferrum 3
bravado 0 14
efdm10 3
skullc 0 14
factoryx 4
q1q3thunderstruck 4
utressor 3
agenda 2
lacrima 3
zed2 3
bless 3 14
croctear 14
warzone 2
"

shuffle_com="cat"
if [ "$shuffle" -eq 1 ];then
	shuffle_com="shuf"
fi
shuffled=$(echo "$maps"|sort -u|$shuffle_com)

newmaps=$(echo -e "${firstmap}\n${shuffled}")

count=0

while read -r line; do
	if [ -z "$line" ];then
		continue
	fi
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
	if [ -z $min ];then
		min=0
	fi
	echo 'set k_ml_minp_'$count' "'$min'"'
	if [ -z $max ];then
		max=0
	fi
	echo 'set k_ml_maxp_'$count' "'$max'"'
	let count=count+1
done <<< "$newmaps"
