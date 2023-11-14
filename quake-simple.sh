#!/bin/bash

quake_path="${quake_path:-$HOME/games/quake}"
quake_exe="${quake_exe:-ezquake-linux-x86_64}"

sudo -n renice -n -5 $$ || echo "warning couldn't set priority, need passwordless sudo."

#mesa
#disable mesa's gl threading
export mesa_glthread=false
#disable smart access memory
#export radeonsi_disable_sam=true

#generic
preload_library="libtcmalloc_minimal.so.4"
if ldconfig -p |grep --color=never $preload_library -c >/dev/null 2>&1;then
	export LD_PRELOAD="$preload_library "
else
	echo "warning $preload_library not found"
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
	export __GL_THREADED_OPTIMIZATIONS=1
fi

oldpath=$(pwd)
cd "$quake_path"

#keep all threads on the same ccx, or set to prefered cores
taskset -c 0-5 ./$quake_exe -no-triple-gl-buffer $*

cd "$oldpath"
exit
