#!/bin/bash

export refreshinterval=4
export output="DisplayPort-0"
export startrefresh="149"
export stoprefresh="175"
export resolution="1920 1080"

deps="cvt12 xrandr"
for dep in $deps;do
	if ! hash $dep >/dev/null 2>&1;then
		echo "missing dep $dep, bailing out."
		exit 1
	fi
done

function cleanexit(){
	xrandr --output "$output" --auto
	exit
}
trap cleanexit SIGINT SIGTERM EXIT

for refresh in $(seq $startrefresh $stoprefresh);do
	for refresh2 in $(echo "0 5 9");do
		modeline=$(cvt12 $resolution ${refresh}.${refresh2} -b |grep --color=never Modeline|awk '{$1= ""; print $0}')
		modename=$(echo "$modeline"|awk '{print $1}')
		modeoutput=$(xrandr --newmode $modeline 2>&1)
		modeoutput+=$(xrandr --addmode $output $modename 2>&1)
		modeoutput+=$(xrandr --output $output --mode $modename 2>&1)
		echo "xrandr --newmode $modeline"
		echo "xrandr --addmode \"$output\" $modename"
		echo "xrandr --output "$output" --mode $modename"
		sleep $refreshinterval
		xrandr --output "$output" --auto
		sleep 2
	done
done
