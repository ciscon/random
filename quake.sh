#!/bin/bash 
# run quake with libnotify notifications and bind individual threads to physical cores

quake_path="/opt/quake"
auto_args="+connectbr 192.168.2.13" #args to append if no arguments are given
nice_level="-19"
nvidia_threaded_optimizations="0"
notify_command="notify-send -t 3000 -i /opt/quake/quake.png"

#kill off children when we exit
trap 'kill $(ps -o pid= --ppid $$)' INT TERM EXIT

#append extra arguments? example: timedemo
#extra_args=" -nosound +s_nosound 1 +timedemo fps.qwd"

if [ -z "$*" ];then
	args="$auto_args"
else
	args="$*"
fi

#nvidia: threaded opt?
if [ $nvidia_threaded_optimizations -eq 1 ];then
	export LD_PRELOAD="libpthread.so.0 libGL.so.1" 
	export __GL_THREADED_OPTIMIZATIONS=1
fi


nice -n $nice_level "$quake_path"/ezquake-linux-x86_64 "$args" -heapsize 262144 -condebug $timedemo &
#timedemo from console - output to qw/qconsole.log
#nice -n -20 "$quake_path"/ezquake-linux-x86_64 -heapsize 262144 -condebug -nosound +s_nosound 1 +timedemo fps.qwd
qpid=$!

#set up notifications
notify_whitelist='entered the game$
éó òåáäù' #player ready

notify_blacklist='^Spectator' #ignore spectators

grep_command='egrep --line-buffered'

OLDIFS=$IFS; IFS=$'\n';

for item in $notify_whitelist;do  grep_command+=" -e '$item'";done

for item in $notify_blacklist;do  grep_command+=" | grep --line-buffered -v -e '$item'";done

IFS=$OLDIFS

#start monitoring of logfile for notifications
tail -n 0 -F "$quake_path"/qw/qconsole.log| eval "$grep_command" | \
while read line; do
        $notify_command "$line" 
done&

#allow threads to spawn
sleep 5

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
