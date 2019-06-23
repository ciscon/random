#!/bin/bash 
#
# source: https://raw.githubusercontent.com/ciscon/random/master/quake.sh
#
# run quake with libnotify notifications (when players are ready/enter by default), bind individual threads to physical cores, and attempt some performance tweaks
#  
#
# note: for everything to work, user must have already authenticated sudo in the shell, or have sudo permission without a password
#       if sudo does not exist or is not configured properly, commands will silently fail, though the user will be asked to authenticate.
#
# to monitor core usage: watch -n .5 'ps -L -o pid,tid,%cpu,comm,psr -p `pgrep ezquake-linux`'
#
# recommended binaries/packages (debian)
#   libnotify-bin: /usr/bin/notify-send
#   sudo: /usr/bin/sudo
#   util-linux: /usr/bin/taskset

#game vars - these most likely need to be customized
quake_path="/opt/quake"
quake_exe="ezquake-linux-x86_64"
auto_args="-no-triple-gl-buffer +connectbr nicotinelounge.com" #args to append if no arguments are given
heapsize="65536" #client default of 32MB
client_port="2018" #choose client port, take default with 0, or random ephemeral with -1


#enable desktop notifications (when users join/ready by default) through libnotify/notify-send?
enable_notifications="1"

#ask user to authenticate if needed?
sudo_ask="1"

#optimization parameters
opengl_multithreading="1" #nvidia/mesa threaded optimizations?
nvidia_settings_optimizations="1" #attempt to use nvidia-settings for various optimized settings?
bind_threads="1" #bind threads to cores?
nice_level="-5" #(sudo)
disable_turbo="0" #disable turbo on intel processors (sudo)



#everything after this point most likely doesn't need to be modified



#set up notifications
notify_command="notify-send --hint=int:transient:2 -t 1500 -i /opt/quake/quake.png"

notify_whitelist='entered the game$
is ready'
notify_blacklist='^Spectator' #ignore spectators

#do we need to translate any of the notifications before displaying them?
translate_command='sed -u "s/M-iM-s M-rM-eM-aM-dM-y.*$/is ready/g"'


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
	echo "taskset not found, we will not be able to bind threads to cores."
	bind_threads=0
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
export __GL_YIELD="NOTHING" #never yield
export __GL_GSYNC_ALLOWED=0 #no gsync
export __GL_SYNC_TO_VBLANK=0 #no vsync
export __GL_ALLOW_UNOFFICIAL_PROTOCOL=1 #incomplete, must have xorg config option AllowUnofficialGLXProtocol
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
	#nvidia: set max performance in case we already haven't
	nvidia-settings -a GPUPowerMizerMode=1 >/dev/null 2>&1
	#set performance over quality
	nvidia-settings -a OpenGLImageSettings=3 >/dev/null 2>&1
	#no buffer swaps
	nvidia-settings -a AllowFlipping=0 >/dev/null 2>&1
	#vsync
	nvidia-settings -a SyncToVBlank=0 >/dev/null 2>&1
	#gl_clamp_to_edge
	nvidia-settings -a TextureClamping=0 > /dev/null 2>&1

	#enable shader cache
	export __GL_SHADER_DISK_CACHE_PATH=/tmp/nvidia_shader_cache
	mkdir -p /tmp/nvidia_shader_cache
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

	#set wmname back
	wmname "" >/dev/null 2>&1&

	#kill child processes
	kill $(jobs -p) >/dev/null 2>&1

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
quake_command="$quake_path/$quake_exe $args -heapsize $heapsize"

if [ $client_port -lt 0 ];then
	quake_command+=" -clientport 0 "
elif [ $client_port -gt 0 ];then
	quake_command+=" -clientport $client_port "
fi
notification_command=" -condebug /dev/stdout > $quake_fifo"


full_command="nice -n $nice_level $quake_command"
if [ $enable_notifications -eq 1 ];then
	full_command+="$notification_command" 
	#spawn notification command
	(cat -v $quake_fifo | stdbuf -i0 -o0 sed 's/M-//g' |eval $grep_command | eval $translate_command | stdbuf -i0 -o0 tr -cd '[[:alnum:] \n]._-' |xargs -I% $notify_command %)&
fi

eval "$full_command 2>&1" &

real_qpid=$!

sleep 1

qpid=$(pgrep -f $quake_exe)

#allow threads to spawn
sleep 5


#use number of physical cores
physcores=$(egrep -e "core id" -e ^physical /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#or use number of hardware threads
cores=$(egrep -e "core id" -e ^processor /proc/cpuinfo|xargs -l2 echo|sort -u|wc -l)
#number of threads spawned
num_qthreads=$(ps --no-headers -L -o tid:1 -p ${qpid} 2>/dev/null|wc -l 2>/dev/null)


#only attempt to set affinity if we have enough hardware threads to handle all threads, otherwise do nothing
if [ $num_qthreads -le $cores ] && [ $bind_threads -eq 1 ];then

	function set_affinity(){
		#set thread affinity - sorted based on cpu usage so our primary threads will definitely get their own cores
		qthreads=$(ps --no-headers -L -o pcpu:1,tid:1 -p ${qpid} 2>/dev/null|sort -nr|head -n $physcores|cut -d" " -f2 2>/dev/null)

		#set affinity, if we run out of physical cores to pin threads to, just use 0 as these are the least cpu hungry threads anyway
		let core=0
		for thread in $qthreads;do
			taskset -p -c $core $thread >/dev/null 2>&1
			if [ $core -lt $physcores  ];then
				let core=core+1
			else
				#let the kernel decide, though we should only be looking at the first n threads in which n is the number of physical cores
				core="-1"
			fi
			if [ ! -z "$sudo_command" ];then
				$sudo_command renice -n $nice_level ${thread} >/dev/null 2>&1 #attempt to set nice level
			fi
		done
	}

	#if we got a number, proceed
	if [[ $cores =~ ^[0-9]+$ ]];then
		if [ $cores -gt 1 ];then
			set_affinity
			sleep 1
			orig_unique=$(ps --no-headers -L -o psr:1 -p ${qpid} 2>/dev/null|uniq -u|wc -l 2>/dev/null)
			#watch to make sure we haven't respawned the threads
			(while [ 1 ];do
					sleep 5
					unique=$(ps --no-headers -L -o psr:1 -p ${qpid} 2>/dev/null|uniq -u|wc -l 2>/dev/null)
					if [ ! -z "$unique" ];then
						if [ $unique -lt $orig_unique ];then
							set_affinity
						fi
					fi
					sleep 1
					orig_unique=$(ps --no-headers -L -o psr:1 -p ${qpid} 2>/dev/null|uniq -u|wc -l 2>/dev/null)
				done)&
		fi
	fi

fi

wait $real_qpid

clean_exit

exit 0
