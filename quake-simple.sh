#!/bin/bash

quake_path="${quake_path:-$HOME/games/quake}"
quake_exe="${quake_exe:-ezquake-linux-x86_64}"

sudo -n renice -n -5 $$ || echo "warning couldn't set priority, need passwordless sudo."

#mesa
#disable mesa's gl threading
export mesa_glthread=false
#disable smart access memory
export radeonsi_disable_sam=true

#generic
if [ ! -f "/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4" ];then
    echo "warning libtcmalloc not found"
else
    unset LD_PRELOAD
    export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4 "
fi

#nvidia
#turn threaded optimizations on
if [ -e /sys/module/nvidia/version ] 2>/dev/null || [ "$mesa_glthread" = "true" ];then
	if [ $(/sbin/ldconfig -Np|grep libpthread.so.0$ -c) -gt 0 ];then
		LD_PRELOAD+="libpthread.so.0 "
	fi
	if [ $(/sbin/ldconfig -Np|grep libGL.so.1$ -c) -gt 0 ];then
		LD_PRELOAD+="libGL.so.1 "
	fi
fi

oldpath=$(pwd)
cd "$quake_path"

#keep all threads on the same ccx, or set to prefered cores
taskset -c 0-5 ./$quake_exe -no-triple-gl-buffer $*

cd "$oldpath"
exit
