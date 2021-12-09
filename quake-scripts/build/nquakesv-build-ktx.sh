#!/bin/bash
# force=1 to skip revision check

gitrepo="https://github.com/Iceman12k/ktx"

#check for git
if ! hash git 2>/dev/null;then
    echo "can't find git.  exiting."
    exit 1
fi

#check for quakestat
if ! hash quakestat 2>/dev/null;then
    echo "can't find quakestat (debian package qstat).  exiting."
    exit 1
fi

#check for build tools
if ! hash make 2>/dev/null || ! hash gcc 2>/dev/null;then
    echo "can't find make/gcc (debian package build-essential).  exiting."
    exit 1
fi

#check for pkg-config
if ! hash pkg-config 2>/dev/null;then
    echo "can't find pkg-config.  exiting."
    exit 1
fi

#where our custom cflags/ldflags exists
. /etc/profile
export CFLAGS+=" -march=native "

if [ ! -d $nquakesv_home/build/ktx ];then
	mkdir -p $nquakesv_home/build
	git clone $gitrepo $nquakesv_home/build/ktx
	force=1
fi


nquakesv_home="$HOME/nquakesv"

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

