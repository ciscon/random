#!/bin/bash

olddir=$(pwd)

rm -rf /tmp/quakeconvert
mkdir -p /tmp/quakeconvert
cd /tmp/quakeconvert

cp /download/games/quake/id1/*.pak . || exit

for i in *.pak;do pakextract $i;done  
cd maps 
for i in *.bsp;do bsputil --extract-textures $i;done  
for i in *.wad;do qpakman -e $i;done  
for i in *.png;do convert $i -set colorspace Gray -separate -average $i;done  
mkdir textures  
mv *.png textures  
zip -r greyscale_textures.pk3 textures

cd "$olddir"

cp /tmp/quakeconvert/greyscale_textures.pk3 .
