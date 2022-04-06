#!/bin/bash
# build mvdsv for various architectures via docker                                                                                                                                                                                                                               

dist="debian"
release="testing"
archs="i386 amd64 arm64v8 armhf"

outputdir="$PWD/output"
gitdir="$PWD/mvdsv"

mkdir -p $outputdir $gitdir

if [ ! -d $gitdir/.git ];then
    echo "git directory for mvdsv not found, please clone to $gitdir"
    exit 1
fi

for arch in $archs;do
    docker pull $arch/$dist:$release
    docker run --net=host --rm --device /dev/fuse -v "$gitdir":/mvdsv $arch/$dist:$release bash -c 'export DEBIAN_FRONTEND=noninteractive;mkdir -p /etc/apt/apt.conf.d;echo "APT::Install-Recommends "0"; APT::AutoRemove::RecommendsImportant "false";" >> /etc/apt/apt.conf.d/01lean && apt-get -qqy update && apt-get -qqy install cmake build-essential libcurl4-openssl-dev && cd /mvdsv && cmake -B build-'$arch' && cd build-'$arch' && make -j$(nproc) && chown -Rf '$(id -u ${USER})':'$(id -g ${USER})' /mvdsv/build*'
    errorcode=$?
    if [ $errorcode -ne 0 ];then
        echo "$arch $errorcode"
        exit 2
    fi
done
