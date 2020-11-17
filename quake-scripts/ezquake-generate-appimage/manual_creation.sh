#!/bin/bash

GIT_COMMIT=""

#unused but must exist
DESKTOP_ENTRY='[Desktop Entry]
Name=ezquake
Exec=ezquake-linux-x86_64
Icon=quake
Type=Application
Categories=Game;'

QUAKE_SCRIPT='#!/usr/bin/env bash
export LD_LIBRARY_PATH="${APPIMAGE_LIBRARY_PATH}:${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
cd "$OWD"
${APPDIR}/usr/bin/ezquake-linux-x86_64 $*'

unset CC
export CFLAGS="-march=nehalem -O3 -pipe -flto=$(nproc) -fwhole-program"
export LDFLAGS="$CFLAGS"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -d AppDir ];then
	rm -rf AppDir
fi
mkdir -p "$DIR/build" || exit 1
mkdir -p "$DIR/AppDir/usr/bin" || exit 1
mkdir -p "$DIR/AppDir/usr/lib" || exit 1

#ezquake git
cd build && \
if [ ! -d ezquake-source ];then
	git clone https://github.com/ezQuake/ezquake-source.git
fi
cd ezquake-source || exit 2
make clean
git clean -qfdx
git reset --hard
git checkout master
git pull
if [ $? -ne 0 ];then
	echo "error updating from git"
	exit 2
fi
if [ ! -z $GIT_COMMIT ];then
	git checkout $GIT_COMMIT
fi
REVISION=$(git log -n 1|head -1|awk '{print $2}'|cut -c1-6)

chmod +x ./build-linux.sh && \
nice ./build-linux.sh || exit 3
cp -f ezquake-linux-x86_64 "$DIR/AppDir/usr/bin/." || exit 4
rm -f "$DIR/AppDir/AppRun"
echo "$QUAKE_SCRIPT" > "$DIR/AppDir/AppRun" || exit 4
chmod +x "$DIR/AppDir/AppRun" || exit 4
echo "$DESKTOP_ENTRY" > "$DIR/AppDir/ezquake.desktop" || exit 4
cp "$DIR/quake.png" "$DIR/AppDir/."||true #copy over quake png if it exists
ldd "$DIR/AppDir/usr/bin/ezquake-linux-x86_64" |grep --color=never -v libpthread|grep --color=never -v libz|grep --color=never -v libGL|grep --color=never -v libc.so|awk '{print $3}'|xargs -I% cp "%" "$DIR/AppDir/usr/lib/." || exit 5
strip -s "$DIR/AppDir/usr/lib/"* || exit 5
strip -s "$DIR/AppDir/usr/bin/"* || exit 5

cd "$DIR" || exit 5
./appimagetool AppDir ezquake-$REVISION.AppImage
