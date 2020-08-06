#!/bin/bash -e
#requires pakextract, bsputil, optipng, and qpakman

#magnify method: eagle2X, eagle3X, eagle3XB, epb2X, fish2X, hq2X, scale2X, scale3X, xbr2X
method="scale2X"

if [ ! -f pak0.pak ];then
	echo "no pak file"
fi

if [ -d maps ];then
	rm -rf maps
fi

for i in *.pak;do pakextract $i;done 
cd maps

#other bsps?
#cp /path/to/other/bsps/*.bsp .

for i in *.bsp;do bsputil --extract-textures $i;done 
for i in *.wad;do qpakman -f -e "$i";done 

#greyscale?
#for i in *.png;do convert $i -set colorspace Gray -separate -average $i;done 

for i in *.png;do 
	convert $i -define magnify:method=$method -magnify -magnify -magnify $i
done 

if [ -d textures ];then
	rm -rf textures
fi
mkdir textures 
mv *.png textures 
cd textures

#optimize pngs
optipng -strip all *.png

#fix names
rename 's/plus_/+/' *.png
rename 's/star_/#/' *.png
rename 's/_fbr//' *.png

cd ..

zip -r ../scale8x.pk3 textures 
