#!/bin/bash

SKIP_BUILD=1

if ! hash appimagetool;then
	echo "appimagetool not installed."
	exit 1
fi
if ! hash patchelf;then
	echo "patchelf not installed."
	exit 1
fi

QUAKE_SCRIPT='
ezquake-linux-x86_64 -basedir "$OWD"
'

DESKTOP_ENTRY='[Desktop Entry]
Name=ezquake
Exec=quake.sh
Icon=quake
Type=Application
Categories=Game;'

unset CC
export CFLAGS="-march=nehalem -O3 -pipe -flto=$(nproc) -fwhole-program"
export LDFLAGS="$CFLAGS"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -d AppDir ];then
	rm -rf AppDir
fi
mkdir -p build && \
mkdir -p AppDir/usr/bin && \
mkdir -p AppDir/usr/lib && \
cd build && \
if [ ! -d ezquake-source ];then
	git clone https://github.com/ezQuake/ezquake-source.git
fi
cd ezquake-source && \
if [ "$SKIP_BUILD" != "1" ];then
	make clean
	git clean -qfdx
fi
git reset --hard
git pull
if [ $? -ne 0 ];then
	echo "error updating from git"
	exit 1
fi
REVISION=$(git log -n 1|head -1|awk '{print $2}'|cut -c1-6)
nice make -j$(nproc) && \
cp -f ezquake-linux-x86_64 "$DIR/AppDir/usr/bin/." || exit 2
rm -f "$DIR/AppDir/AppRun"
cp -f "$DIR/AppRun-x86_64" "$DIR/AppDir/AppRun" || exit 2
chmod +x "$DIR/AppDir/AppRun" || exit 2
echo "$DESKTOP_ENTRY" > "$DIR/AppDir/ezquake.desktop" || exit 2
echo "$QUAKE_SCRIPT" > "$DIR/AppDir/usr/bin/quake.sh" || exit 2
chmod +x "$DIR/AppDir/usr/bin/quake.sh" || exit 2
cp "$DIR/quake.png" "$DIR/AppDir/."||true #copy over quake png if it exists
cd "$DIR" && \
ldd AppDir/usr/bin/ezquake-linux-x86_64 |grep --color=never -v libz|grep --color=never -v libGL|grep --color=never -v libc.so|awk '{print $3}'|xargs -I% cp "%" AppDir/usr/lib/. && \

appimagetool AppDir ezquake-$REVISION.AppImage
