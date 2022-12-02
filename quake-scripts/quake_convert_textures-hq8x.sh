#!/bin/bash -e
#requires bsputil, imagemagick mogrify, and qpakman
#optional - optipng

#magnify method: eagle2X, eagle3X, eagle3XB, epb2X, fish2X, hq2X, scale2X, scale3X, xbr2X
method="scale2X"
scaletimes="-magnify -magnify -magnify"

deps="mogrify bsputil qpakman"
for dep in $deps;do
    if ! hash $dep >/dev/null 2>&1;then
        echo "missing dep $dep, bailing out."
        exit 1
    fi
done

if [ ! -f pak0.pak ];then
	echo "no pak file"
fi

if [ -d maps ];then
	rm -rf maps
fi

for i in *.pak;do qpakman -e $i;done 
cd maps

#other bsps?
#cp /path/to/other/bsps/*.bsp .

for i in *.bsp;do bsputil --extract-textures $i;done
for i in *.wad;do qpakman -f -e "$i";done

#greyscale?
#for i in *.png;do mogrify -set colorspace Gray -separate -average $i;done

for i in *.png;do
	mogrify -define magnify:method=$method $scaletimes $i
done 

if [ -d textures ];then
	rm -rf textures
fi
mkdir textures 
mv *.png textures 
cd textures

#optimize pngs?
#optipng -strip all *.png

#fix names
rename 's/plus_/+/' *.png
rename 's/star_/#/' *.png
rename 's/_fbr//' *.png

cd ..

zip -r ../scale8x.pk3 textures 
