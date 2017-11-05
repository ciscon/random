#!/bin/bash 
# run quake with libnotify notifications and bind individual threads to physical cores
# note: for everything to work, user must have already authenticated sudo in the shell, or have sudo permission without a password
#
# to monitor core usage: watch -n .5 'ps -L -o pid,tid,%cpu,comm,psr -p `pgrep ezquake-linux`'
#
# required binaries/packages (debian)
#   libnotify-bin: /usr/bin/notify-send
#   sudo: /usr/bin/sudo
#   util-linux: /usr/bin/taskset


#optimization parameters
nvidia_threaded_optimizations="1" #nvidia threaded optimizations?
bind_threads="1" #bind threads to cores?
disable_turbo="1" #disable turbo on intel processors (requires passwordless sudo or will fail)
sudo_command="sudo -n" #which sudo command to use, non-interactive is default, this will just fail silently if sudo requires a password
nice_level="-10" #uses sudo_command

quake_path="/opt/quake"
quake_exe="ezquake-linux-x86_64"
auto_args="+connectbr nicotinelounge.com" #args to append if no arguments are given
notify_command="notify-send -t 1500 -i /opt/quake/quake.png"

#set up notifications
notify_whitelist='entered the game$
M-iM-s M-rM-eM-aM-dM-y' #player ready
notify_blacklist='^Spectator' #ignore spectators

#do we need to translate any of the notifications before displaying them?
translate_command='sed -u "s/M-iM-s M-rM-eM-aM-dM-y.*$/is ready/g"'

#parse white/blacklist for notifications
grep_command='egrep --line-buffered'



#set up environment:
export __GL_YIELD="NOTHING" #never yield

#nvidia: threaded opt?
if [ $nvidia_threaded_optimizations -eq 1 ];then
	export LD_PRELOAD="libpthread.so.0 libGL.so.1" 
	export __GL_THREADED_OPTIMIZATIONS=1
fi


if [ $disable_turbo -eq 1 ];then
	echo 1 |sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 &
fi


#disable nmi watchdog
$sudo_command sysctl kernel.nmi_watchdog=0 >/dev/null 2>&1 &


#dwm fix
wmname LG3D >/dev/null 2>&1

function clean_exit(){

	#enable turbo again
	if [ $disable_turbo -eq 1 ];then
		echo 0 |$sudo_command tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 &
	fi
	
	#set wmname back
	wmname "" >/dev/null 2>&1
	
}

#kill off children when we exit
trap 'clean_exit;kill $(ps -o pid= --ppid $$) >/dev/null 2>&1' INT TERM EXIT

#default arguments
if [ -z "$*" ];then
	args="$auto_args"
else
	args="$*"
fi


OLDIFS=$IFS; IFS=$'\n';

for item in $notify_whitelist;do  grep_command+=" -e '$item'";done

for item in $notify_blacklist;do  grep_command+=" | grep --line-buffered -v -e '$item'";done

IFS=$OLDIFS



#spawn quake process and parse stdout for notifications
"$quake_path"/"$quake_exe" $args -heapsize 262144 -condebug /dev/stdout | cat -v | eval "$grep_command" | eval "$translate_command" |xargs -I% $notify_command "%" &

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
			$sudo_command renice -n $nice_level ${thread} >/dev/null 2>&1 #attempt to set nice level
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
			sleep 1
			orig_unique=$(ps --no-headers -L -o psr:1 -p ${qpid}|uniq -u|wc -l)
			#watch to make sure we haven't respawned the threads
			(while [ 1 ];do
				sleep 5
				unique=$(ps --no-headers -L -o psr:1 -p ${qpid}|uniq -u|wc -l)
				if [ ! -z "$unique" ];then
					if [ $unique -lt $orig_unique ];then
						set_affinity
					fi
				fi
				sleep 1
				orig_unique=$(ps --no-headers -L -o psr:1 -p ${qpid}|uniq -u|wc -l)
			done)&
		fi
	fi

fi

wait $qpid

clean_exit

exit 0
