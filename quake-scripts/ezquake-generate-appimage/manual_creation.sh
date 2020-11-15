#!/bin/bash
if ! hash appimagetool;then
	echo "appimagetool not installed."
	exit 1
fi

DESKTOP_ENTRY="[Desktop Entry]
Name=ezquake
Exec=ezquake-linux-x86_64
Icon=quake
Type=Application
Categories=Game;"

unset CC
export CFLAGS="-march=nehalem -O3 -pipe -flto=$(nproc) -fwhole-program"
export LDFLAGS="$CFLAGS"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -p build && \
mkdir -p AppDir/usr/bin && \
mkdir -p AppDir/usr/lib && \
cd build && \
if [ ! -d ezquake-source ];then
	git clone https://github.com/ezQuake/ezquake-source.git
fi
cd ezquake-source && \
git clean -qfdx
git reset --hard
git pull
if [ $? -ne 0 ];then
	echo "error updating from git"
	exit 1
fi
REVISION=$(git log -n 1|head -1|awk '{print $2}'|cut -c1-6)
make clean && \
nice make -j$(nproc) && \
cp -f ezquake-linux-x86_64 "$DIR/AppDir/usr/bin/." && \
ln -sf usr/bin/ezquake-linux-x86_64 "$DIR/AppDir/AppRun" && \
echo "$DESKTOP_ENTRY" > "$DIR/AppDir/ezquake.desktop" && \
cp "$DIR/quake.png" "$DIR/AppDir/."||true #copy over quake png if it exists
cd "$DIR" && \
ldd AppDir/usr/bin/ezquake-linux-x86_64 |grep --color=never -v libGL|grep --color=never -v libc.so|awk '{print $3}'|xargs -I% cp "%" AppDir/usr/lib/. && \
appimagetool AppDir ezquake-$REVISION.AppImage
