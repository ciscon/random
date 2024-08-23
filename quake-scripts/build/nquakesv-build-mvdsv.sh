#!/bin/bash
# force=1 to skip revision check

gitrepo="https://github.com/QW-Group/mvdsv.git"
gitbranch="master"

deps="git pkill quakestat make gcc pkg-config cmake"
for dep in $deps;do
	if ! hash $dep >/dev/null 2>&1;then
		echo "missing dep $dep, bailing out."
		echo "try: apt-file search $dep"
		exit 1
	fi
done

#where our custom cflags/ldflags exists
. /etc/profile
export CFLAGS+=" -march=native "

nquakesv_home="$HOME/nquakesv"

#check current remote revision
remotehead=$(git ls-remote "$gitrepo" $gitbranch|head -1|awk '{print $1}'|cut -c1-6)

if [ -z "$remotehead" ];then
	echo "couldn't retrieve remote head"
	exit 1
fi

if [ "$force" != "1" ];then
	#check whether or not we need to proceed
	for bin in "${nquakesv_home}/"mvdsv-*-??????;do
		temprev=$(echo "$bin"|awk -F'[.-]' '{print $NF}')
		if [ "$temprev" = "$remotehead" ];then
			echo "revision already built, exiting."
			exit 0
		fi
	done
fi

if [ ! -d "$nquakesv_home/build/mvdsv" ];then
	mkdir -p "$nquakesv_home/build"
	echo "cloning repo..."
	git clone $gitrepo "$nquakesv_home/build/mvdsv" >/dev/null 2>&1
	force=1
fi

cd "$nquakesv_home/build/mvdsv"

echo "resetting git repo..."
git remote set-url origin "$gitrepo" >/dev/null 2>&1
git fetch --all >/dev/null 2>&1
git clean -qfdx >/dev/null 2>&1
git reset --hard >/dev/null 2>&1
git checkout $gitbranch >/dev/null 2>&1
git submodule update --init --recursive --remote >/dev/null 2>&1
git reset --hard origin/$gitbranch >/dev/null 2>&1
git clean -qfdx >/dev/null 2>&1
git config pull.rebase false >/dev/null 2>&1

if [ "$force" != "1" ];then
	echo "updating git repo..."
	output=$(git pull --no-commit 2>&1)
	if [ $? -ne 0 ];then
		echo "failed to update git, bailing out."
		echo "git pull output: $output"
		exit 2
	fi
fi

set -e

VERSION=$(sed -n 's/.*SERVER_VERSION.*"\(.*\)".*/\1/p' src/version.h)
REVISION=$(git log -n 1|head -1|awk '{print $2}'|cut -c1-6)

echo "configuring source..."
if [ -f ./CMakeLists.txt ];then
	cmake . >/dev/null 2>&1
elif [ -f ./configure ];then
	chmod +x configure
	./configure >/dev/null 2>&1
else
	cd ./build/make
	chmod +x configure
	./configure >/dev/null 2>&1
fi

##wait until all ports are empty
declare -A dirtyports
while [ 1 ];do
	if [ ${#dirtyports[@]} -ne 0 ];then
		clean=1
		for key in "${!dirtyports[@]}";do
			if [ "${dirtyports[$key]}" = 1 ];then
				echo "client(s) connected to port $key, waiting."
				clean=0         
				sleep 5
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

echo "building..."

nice make -j3 >/dev/null 2>&1 && \
	(pkill -f "mvdsv -port"||true);sleep 1;(pkill -9 -f "mvdsv -port"||true) >/dev/null 2>&1 ; \
	cp mvdsv "$nquakesv_home/mvdsv-${VERSION}-${REVISION}" && \
	strip "$nquakesv_home/mvdsv-${VERSION}-${REVISION}" && \
	ln -sf "mvdsv-${VERSION}-${REVISION}" "$nquakesv_home/mvdsv"

echo "complete."
