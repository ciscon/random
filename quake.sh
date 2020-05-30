#!/bin/bash 
#
# source: https://raw.githubusercontent.com/ciscon/random/master/quake.sh
#
# run quake with libnotify notifications (when players are ready/enter by default), attempt performance tweaks for various gpus, set affinity of quake process
#    depprecated: bind individual threads to physical cores, and attempt some performance tweaks
#  
#
# note: for everything to work, user must have already authenticated sudo in the shell, or have sudo permission without a password and supporting tools must exist
#       if sudo does not exist or is not configured properly, commands will silently fail, though the user will be asked to authenticate.
#
# to monitor core usage: watch -n .5 'ps -L -o pid,tid,%cpu,comm,psr -p `pgrep ezquake-linux`'
#
# recommended binaries/packages (debian)
#   libnotify-bin: /usr/bin/notify-send
#   sudo: /usr/bin/sudo
#   util-linux: /usr/bin/taskset


#create this file and put any of the following variables in them to override defaults
. ${HOME}/.quake_script_prefs.sh >/dev/null 2>&1


#game vars - these most likely need to be customized
quake_path="${quake_path:-$HOME/games/quake}"
quake_exe="${quake_exe:-ezquake-linux-x86_64}"
auto_args="${auto_args:-+connectbr nicotinelounge.com}" #args to append if no arguments are given
always_args="${always_args:--no-triple-gl-buffer}" #always prepend these arguments
mem="${mem:-128}" #client default is 32MB
client_port="${client_port:--1}" #choose client port, take default with 0, or random ephemeral with -1

#enable desktop notifications (when users join/ready by default) through libnotify/notify-send?
enable_notifications="${enable_notifications:-1}"

#ask user to authenticate if needed?
sudo_ask="${sudo_ask:-1}"

#optimization parameters
opengl_multithreading="${opengl_multithreading:-0}" #nvidia/mesa threaded optimizations?
nvidia_prerendered_frames="${nvidia_prerendered_frames:-0}" #as of the 4xx driver series, 0 is application controlled (2).  1 is the lowest latency setting, but will cause a significant fps drop
nvidia_allow_page_flipping="${nvidia_allow_page_flipping:-0}"
nvidia_settings_optimizations="${nvidia_settings_optimizations:-1}" #attempt to use nvidia-settings for various optimized settings?
nice_level="${nice_level:--5}" #(sudo)
disable_turbo="${disable_turbo:-0}" #disable turbo on intel processors (sudo)
set_affinity="${set_affinity:-0}" #set process affinity
affinity_cores="${affinity_cores:-2,3}" #cores to use for process and underlying threads, comma separated list (no spaces)

#deprecated
#bind_threads="0" #bind threads to cores?
#bind_threads_check_interval="99999" #time in seconds to way between checking that threads are still bound properly
#max_threads="0" #once this number is hit, all remaining threads will be bound to this core

#everything after this point most likely doesn't need to be modified


#set up notifications
notify_command="notify-send --hint=int:transient:2 -t 1500 -i /opt/quake/quake.png"

notify_whitelist='entered the game
is ready'
notify_blacklist='^Spectator' #ignore spectators

#do we need to translate any of the notifications before displaying them?
#isready=$'\362\345\341\344\371'
isready=$'\351\363.*\362\345\341\344\371'
translate_command='sed -u "s/$isready/is ready\n/g;s/[^a-zA-Z0-9 _]//g"'

sudo_command=""
if [ "$sudo_ask" -eq 1 ];then
	#do we have passwordless sudo?
	if ! sudo -n echo >/dev/null 2>&1;then
		echo "authenticate for sudo commands"
		sudo echo -n
	fi
fi
#do we have passwordless sudo now?
if sudo -n echo >/dev/null 2>&1;then
	sudo_command="sudo -n" #which sudo command to use, if we cannot run passwordless sudo, give user a warning
else
	echo "warning, not all optimizations and settings can be implemented as we do not have sudo.  please run sudo before this script to authenticate."
fi

if ! taskset --help >/dev/null 2>&1;then
	echo "taskset not found, we will not be able to set affinity."
	set_affinity=0
	#bind_threads=0
fi

#parse white/blacklist for notifications
grep_command='egrep --line-buffered'


quake_fifo="/tmp/quake_fifo"

if [ ! -p $quake_fifo ];then
	mkfifo $quake_fifo
fi



#check that dir and bin actually exist
if [ ! -d "$quake_path" ] || [ ! -f "$quake_path/$quake_exe" ];then
	echo "quake path or executable not found, please check these variables!  bailing out."
	exit 1
fi

#set up environment:
#nvidia
export __GL_YIELD="NOTHING" #never yield
export __GL_GSYNC_ALLOWED=0 #no gsync
export __GL_SYNC_TO_VBLANK=0 #no vsync
export __GL_ALLOW_UNOFFICIAL_PROTOCOL=1 #incomplete, must have xorg config option AllowUnofficialGLXProtocol
export __GL_MaxFramesAllowed=${nvidia_prerendered_frames} #number of pre-rendered frames
#generic
export vblank_mode=0 #no vsync


if [ ! -z "$sudo_command" ];then

	#gpu: attempt to force the gpu to its highest clock (non nvidia)
	maxclock=$(head -n 1 /sys/devices/*/*/drm/card0/gt_boost_freq_mhz 2>/dev/null)
	if [ ! -z "$maxclock" ];then
		echo "$maxclock"|$sudo_command tee /sys/devices/*/*/drm/card0/gt_min_freq_mhz >/dev/null 2>&1 &
	fi
	#for for amdgpu folks
	if [ -e /sys/class/drm/card0/device/power_dpm_force_performance_level ];then
		echo high|$sudo_command tee /sys/class/drm/card*/device/power_dpm_force_performance_level >/dev/null 2>&1 &
	fi
	#older amd cards
	if [ -e /sys/class/drm/card0/device/power_dpm_state ];then
		echo performance|$sudo_command tee /sys/class/drm/card*/device/power_dpm_force_performance_level >/dev/null 2>&1 &
	fi

	#cpu: set performance governor if we can
	for i in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor;do
		echo performance|$sudo_command tee "$i" >/dev/null 2>&1 &
	done

fi


if [ $nvidia_settings_optimizations -eq 1 ];then
	#nvidia: set max performance in case we already haven't, must be set per gpu
	nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" >/dev/null 2>&1
	#set performance over quality
	nvidia-settings -a OpenGLImageSettings=3 >/dev/null 2>&1
	#buffer swaps
	nvidia-settings -a AllowFlipping=${nvidia_allow_page_flipping} >/dev/null 2>&1
	#vsync
	nvidia-settings -a SyncToVBlank=0 >/dev/null 2>&1
	#gl_clamp_to_edge
	nvidia-settings -a TextureClamping=1 > /dev/null 2>&1
fi

#opengl multithreading
if [ $opengl_multithreading -eq 1 ];then

	if [ $(/sbin/ldconfig -Np|grep libpthread.so.0$ -c) -gt 0 ];then
		LD_PRELOAD+="libpthread.so.0 "
	fi
	if [ $(/sbin/ldconfig -Np|grep libGL.so.1$ -c) -gt 0 ];then
		LD_PRELOAD+="libGL.so.1 "
	fi

	export __GL_THREADED_OPTIMIZATIONS=1
	export mesa_glthread=true
else
	#explicitly disable threading
	export __GL_THREADED_OPTIMIZATIONS=0
	export mesa_glthread=false
fi

if [ ! -z "$LD_PRELOAD" ];then
	echo "Preloading: $LD_PRELOAD"
fi
export LD_PRELOAD

if [ $disable_turbo -eq 1 ] && [ ! -z "$sudo_command" ];then
	echo 1 |$sudo_command tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 &
fi


#disable nmi watchdog
if [ ! -z "$sudo_command" ];then
	$sudo_command sysctl kernel.nmi_watchdog=0 >/dev/null 2>&1 &
fi

#xfce compositing - turn off
xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s false >/dev/null 2>&1


#dwm fix
wmname LG3D >/dev/null 2>&1

function clean_exit(){

	#xfce compositing - turn back on
	xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s true >/dev/null 2>&1&

	#enable turbo again
	if [ $disable_turbo -eq 1 ] && [ ! -z "$sudo_command" ];then
		echo 0 |$sudo_command tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1 &
	fi

	#kill child processes
	kill $(jobs -p) >/dev/null 2>&1
	sleep 1
	kill -9 -$$ >/dev/null 2>&1


}

#kill off children when we exit
trap 'clean_exit;kill $(ps -o pid= --ppid $$) >/dev/null 2>/dev/null' INT TERM EXIT

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
quake_command="$quake_path/$quake_exe $args -mem $mem $always_args"

if [ $client_port -lt 0 ];then
	quake_command+=" -clientport 0 "
elif [ $client_port -gt 0 ];then
	quake_command+=" -clientport $client_port "
fi
notification_command=" -condebug $quake_fifo"


if [ $set_affinity -eq 1 ];then
	full_command="taskset -c $affinity_cores " 
else
	full_command=""
fi

full_command+="nice -n $nice_level $quake_command"
if [ $enable_notifications -eq 1 ];then
	full_command+="$notification_command" 
	#spawn notification command
	(cat $quake_fifo | eval $translate_command | stdbuf -i0 -o0 -e0 tr -dc '\0-\177' | eval $grep_command | xargs -I% $notify_command %)&
fi

eval "$full_command 2>&1" &

real_qpid=$!

sleep 1

qpid=$(pgrep -f $quake_exe)

if [ ! -z "$sudo_command" ];then
	$sudo_command renice -n $nice_level ${qpid} >/dev/null 2>&1 #attempt to set nice level
fi



#deprecated

##allow threads to spawn
#sleep 5
#
#
##use number of physical cores
#physcores=$(egrep -e "core id" -e ^physical /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#physcores=${physcores:-1}
##or use number of hardware threads
#cores=$(egrep -e "core id" -e ^processor /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#cores=${cores:-physcores}
#let step=cores/physcores
##number of threads spawned
#num_qthreads=$(ps --no-headers -L -o tid:1 -p ${qpid} 2>/dev/null|wc -l 2>/dev/null)
#
#
##only attempt to set affinity if we have enough hardware threads to handle all threads, otherwise do nothing
#if [ $num_qthreads -le $cores ] && [ $bind_threads -eq 1 ];then
#
#	if [ $max_threads -gt 0 ];then
#		let max_threads=max_threads-1
#	else
#		max_threads=255
#	fi
#
#	function set_affinity(){
#		#set thread affinity - sorted based on cpu usage so our primary threads will definitely get their own cores
#		qthreads=$(ps --no-headers -L -o pcpu:1,tid:1 -p ${qpid} 2>/dev/null|sort -nr|head -n $physcores|cut -d" " -f2 2>/dev/null)
#
#		#set affinity, if we run out of physical cores to pin threads to, just use 0 as these are the least cpu hungry threads anyway
#		local core=0
#		for thread in $qthreads;do
#			taskset -p -c $core $thread >/dev/null 2>&1
#			if [ $core -lt $cores ] && [ $core -lt $max_threads  ];then
#				let core=core+step
#			elif [ $max_threads -eq -1 ];then
#				#let the kernel decide, though we should only be looking at the first n threads in which n is the number of physical cores
#				core="-1"
#			fi
#			if [ ! -z "$sudo_command" ];then
#				$sudo_command renice -n $nice_level ${thread} >/dev/null 2>&1 #attempt to set nice level
#			fi
#		done
#	}
#
#	renice -n 20 $$ >/dev/null 2>&1
#
#	#if we got a number, proceed
#	if [[ $cores =~ ^[0-9]+$ ]];then
#		if [ $cores -gt 1 ];then
#			sleep 5
#
#			rm -f /tmp/quake_taskset
#			mkfifo /tmp/quake_taskset
#			exec 3<> /tmp/quake_taskset
#
#			#watch to make sure we haven't respawned the threads
#			(
#				while [ 1 ];do
#					taskset --all-tasks -p ${qpid}|tr -d '\n' 1>&3
#					printf '\n' 1>&3
#					read -u3 unique
#
#					if [ ! -z "$unique" ];then
#						if [ "$unique" != "$orig_unique" ];then
#							echo set_affinity
#							set_affinity
#							sleep 5 
#
#							taskset --all-tasks -p ${qpid}|tr -d '\n' 1>&3
#							printf '\n' 1>&3
#							read -u3 orig_unique
#						fi
#					fi
#					sleep $bind_threads_check_interval
#				done
#			)&
#		fi
#	fi
#
#fi

wait $real_qpid

clean_exit

exit 0
