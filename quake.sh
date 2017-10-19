#!/bin/bash 
# run quake with libnotify notifications and bind individual threads to physical cores

quake_path="/opt/quake"
auto_args="+connectbr nicotinelounge.com" #args to append if no arguments are given
nice_level="-19"
nvidia_threaded_optimizations="0"
notify_command="notify-send -t 1500 -i /opt/quake/quake.png"

#set up notifications
notify_whitelist='entered the game$
M-iM-s M-rM-eM-aM-dM-y' #player ready
notify_blacklist='^Spectator' #ignore spectators

#do we need to translate any of the notifications before displaying them?
translate_command='sed -u "s/M-iM-s M-rM-eM-aM-dM-y.*$/is ready/g"'

#append extra arguments? example: timedemo
#extra_args=" -nosound +s_nosound 1 +timedemo fps.qwd"


#kill off children when we exit
trap 'kill $(ps -o pid= --ppid $$)' INT TERM EXIT


#parse white/blacklist for notifications
grep_command='egrep --line-buffered'

OLDIFS=$IFS; IFS=$'\n';

for item in $notify_whitelist;do  grep_command+=" -e '$item'";done

for item in $notify_blacklist;do  grep_command+=" | grep --line-buffered -v -e '$item'";done

IFS=$OLDIFS


#nvidia: threaded opt?
if [ $nvidia_threaded_optimizations -eq 1 ];then
	export LD_PRELOAD="libpthread.so.0 libGL.so.1" 
	export __GL_THREADED_OPTIMIZATIONS=1
fi


if [ -z "$*" ];then
	args="$auto_args"
else
	args="$*"
fi


#spawn quake process and parse stdout for notifications
nice -n $nice_level "$quake_path"/ezquake-linux-x86_64 "$args" -heapsize 262144 -condebug /dev/stdout $timedemo | cat -v | eval "$grep_command" | eval "$translate_command" |xargs -I% $notify_command "%" &
qpid=$!

#allow threads to spawn
sleep 5


#begin thread affinity

#number of physical cores
cores=$(egrep -e "core id" -e ^physical /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)

#if we got a number, proceed
if [[ $cores =~ ^[0-9]+$ ]];then

	#set thread affinity - sorted based on cpu usage so our primary threads will definitely get their own cores
	qthreads=$(ps --no-headers -mo pcpu:1,tid:1 -p ${qpid}|tail -n+2|sort -nr|cut -d" " -f2)
	
	#set affinity, if we run out of physical cores to pin threads to, let the system decide where they go
	core=0
	for thread in $qthreads;do
		if [ $core -lt $cores ];then
			taskset -p -c $core $thread >/dev/null 2>&1
		fi
		let core=core+1 
	done

fi


wait $qpid

exit 0
