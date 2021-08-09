#!/bin/bash
# force=1 to skip revision check

nquakesv_home="$HOME/nquakesv"

#check for git
if ! hash git;then
	echo "can't find git.  exiting."
	exit 1
fi

#check for quakestat
if ! hash quakestat;then
	echo "can't find quakestat.  exiting."
	exit 1
fi

#where our custom cflags/ldflags exists
. /etc/profile
export CFLAGS+=" -march=native "

if [ ! -d $nquakesv_home/build/ktx ];then
	git clone https://github.com/Iceman12k/ktx $nquakesv_home/build/ktx
	force=1
fi
cd $nquakesv_home/build/ktx

if [ "$force" != "1" ];then
	update=$(git reset --hard >/dev/null 2>&1;git pull 2>&1|grep Updating -c)
else
	update=1
fi

set -e

if [ $update -gt 0 ];then

	(make clean||true)
	chmod +x configure
	./configure
	(make clean||true)

	##wait until all ports are empty
	declare -A dirtyports
	while [ 1 ];do
		if [ ${#dirtyports[@]} -ne 0 ];then
			clean=1
			for key in "${!dirtyports[@]}";do
				if [ "${dirtyports[$key]}" = 1 ];then
					echo "clean 0"
					clean=0         
				fi
			done
			if [ $clean -eq 1 ];then
				break
			fi
		fi
		for portfile in $HOME/.nquakesv/ports/*;do
			port=$(basename $portfile)
			clients=$(quakestat -raw ',' -qws localhost:$port -P -nh|grep -a -v '^$'|wc -l)
			if [ $clients -lt 2 ];then
				dirtyports[$port]=0
			else
				dirtyports[$port]=1
			fi
			sleep 1
		done
	done 

	nice make -j3 build-dlbots && cp qwprogs.so $nquakesv_home/ktx/qwprogs.so && strip $nquakesv_home/ktx/qwprogs.so

fi

