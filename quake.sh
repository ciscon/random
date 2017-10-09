#!/bin/bash

#nvidia: threaded opt?
#export LD_PRELOAD="libpthread.so.0 libGL.so.1" 
#export __GL_THREADED_OPTIMIZATIONS=1

autoconnect_host="192.168.2.13"

if [ -z "$*" ];then
	args="+connectbr $autoconnect_host"
else
	args="$*"
fi

nice -n -20 /opt/quake/ezquake-linux-x86_64 "$args" -heapsize 262144&
qpid=$!

#timedemo from console - output to qw/qconsole.log
#nice -n -20 /opt/quake/ezquake-linux-x86_64 -heapsize 262144 -condebug -nosound +s_nosound 1 +timedemo fps.qwd

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

wait
