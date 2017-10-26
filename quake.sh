#!/bin/bash 
# run quake with libnotify notifications and bind individual threads to physical cores
#
# to monitor core usage: watch -n .5 'ps -L -o pid,tid,%cpu,comm,psr -p `pgrep ezquake-linux`'

#optimization parameters
nvidia_threaded_optimizations="1" #nvidia threaded optimizations?
bind_threads="1" #bind threads to cores?

quake_path="/opt/quake"
quake_exe="ezquake-linux-x86_64"
auto_args="+connectbr nicotinelounge.com" #args to append if no arguments are given
nice_level="-19"
notify_command="notify-send -t 1500 -i /opt/quake/quake.png"

#set up notifications
notify_whitelist='entered the game$
M-iM-s M-rM-eM-aM-dM-y' #player ready
notify_blacklist='^Spectator' #ignore spectators

#do we need to translate any of the notifications before displaying them?
translate_command='sed -u "s/M-iM-s M-rM-eM-aM-dM-y.*$/is ready/g"'

#append extra arguments? example: timedemo
#extra_args=" -nosound +s_nosound 1 +timedemo fps.qwd"

export __GL_YIELD="NOTHING" #never yield

#dwm
wmname LG3D >/dev/null 2>&1

#kill off children when we exit
#trap 'sleep 1;kill -- -$$' INT TERM EXIT
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
nice -n $nice_level "$quake_path"/$quake_exe "$args" -heapsize 262144 -condebug /dev/stdout $timedemo | cat -v | eval "$grep_command" | eval "$translate_command" |xargs -I% $notify_command "%" &

sleep 1

qpid=$(pgrep -f $quake_exe)

#allow threads to spawn
sleep 5


#use number of physical cores
physcores=$(egrep -e "core id" -e ^physical /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#or use number of hardware threads
cores=$(egrep -e "core id" -e ^processor /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#number of threads spawned
num_qthreads=$(ps --no-headers -L -o tid:1 -p ${qpid}|wc -l)


#only attempt to set affinity if we have enough hardware threads to handle all threads, otherwise do nothing
if [ $num_qthreads -le $cores ] && [ $bind_threads -eq 1 ];then

	function set_affinity(){
		#set thread affinity - sorted based on cpu usage so our primary threads will definitely get their own cores
		qthreads=$(ps --no-headers -L -o pcpu:1,tid:1 -p ${qpid}|sort -nr|cut -d" " -f2)
		
		#set affinity, if we run out of physical cores to pin threads to, let the system decide where they go
		core=0
		for thread in $qthreads;do
			if [ $core -lt $physcores ];then
				taskset -p -c $core $thread >/dev/null 2>&1
				let core=core+1 
			fi
		done
	}
	
	
	#if we got a number, proceed
	if [[ $cores =~ ^[0-9]+$ ]];then
		if [ $cores -gt 1 ];then
			set_affinity
			#watch to make sure we haven't respawned the threads
			(while [ 1 ];do
				sleep 5
				unique=$(ps --no-headers -L -o psr:1 -p ${qpid}|uniq -u)
				if [ -z "$unique" ];then
					set_affinity
				fi
			done)&
		fi
	fi

fi

wait $qpid

exit 0
