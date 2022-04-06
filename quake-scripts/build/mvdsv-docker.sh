#!/bin/bash
# build mvdsv for various architectures via docker

dist="debian"
release="testing"
archs="i386 amd64 arm64v8 arm32v7"

gitdir="$PWD/mvdsv"

mkdir -p $gitdir

if [ ! -d $gitdir/.git ];then
	echo "git directory for mvdsv not found, please clone to $gitdir"
	exit 1
fi

for arch in $archs;do
	docker pull $arch/$dist:$release
	docker run --net=host --rm --device /dev/fuse -v "$gitdir":/mvdsv $arch/$dist:$release bash -c 'export ARCH=$(dpkg --print-architecture);export DEBIAN_FRONTEND=noninteractive;mkdir -p /etc/apt/apt.conf.d;echo "APT::Install-Recommends "0"; APT::AutoRemove::RecommendsImportant "false";" >> /etc/apt/apt.conf.d/01lean && apt-get -qqy update && apt-get -qqy dist-upgrade && apt-get -qqy install cmake build-essential libcurl4-openssl-dev && ln -sf "$(which make)" /usr/bin/gmake && cd /mvdsv && cmake -B build-$ARCH && cd build-$ARCH && make -j$(nproc) && chown -Rf '$(id -u ${USER})':'$(id -g ${USER})' /mvdsv/build*'
	errorcode=$?
	if [ $errorcode -ne 0 ];then
		echo "$arch $errorcode"
		exit 2
	fi
done
