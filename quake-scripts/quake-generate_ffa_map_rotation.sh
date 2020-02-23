#!/bin/bash
#generate ffa map rotation using specified list in the following format:
#	mapname minplayers maxplayers

#shuffle map cycle?
shuffle=1

#this is our fallback map
firstmap="ultrav"

maps="
croctear 10
e4m3 10
e1m2 8
e1m5 8
schloss 8
zed2 6
dark-terror-ffa 5
dark-storm-ffa 5
four 5
e1m7 5
#doomed 5
travelert6 5
jvx1 5
blizz2 3
#rwild 3
spellsgate 3
spinev2 3
shifter 3
ztndm5 2
burialb2 0 14
qwdm1 3
ztndm4 2
aerowalk 0 14
dm2 3
debello 3
ztndm2 4
p3a 2
a2 3
pkeg1 2
river 3
ztndm3
efdm8 3
rf2 2
subterfuge 2
spitfire 3
ztndm6 3
trw 2
ferrum 3
bravado 0 14
efdm10 3
skull666 0 14
factoryx 4
utressor 3
agenda 2
lacrima 3
bless 3 14
warzone 2 14
catalyst 2
"

shuffle_com="cat"
if [ "$shuffle" -eq 1 ];then
	shuffle_com="shuf"
fi
shuffled=$(echo "$maps"|sort -u|grep --color=never -v '^#'|$shuffle_com)

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
