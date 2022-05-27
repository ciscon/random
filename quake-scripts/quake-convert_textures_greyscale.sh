#!/bin/bash

tmpdir="/tmp/quakeconvert"
id1="./id1"

#uses the following programs
uses="bsputil qpakman mogrify zip"

#test for needed programs
for program in $uses;do
    if ! hash $program 2>/dev/null;then
        echo "$program not installed.  bailing out."
        exit 1
    fi
done

olddir=$(pwd)

rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir

cp /mnt/nas-quake/id1/*.pak . || exit

for i in *.pak;do qpakman -f -e $i;done
cd maps
for i in *.bsp;do bsputil --extract-textures $i;done
for i in *.wad;do qpakman -f -e $i;done
mogrify -set colorspace Gray -separate -average *.png
mkdir textures  
mv *.png textures  
zip -r -9 $tmpdir/greyscale_textures.pk3 textures

cd "$olddir"

cp $tmpdir/greyscale_textures.pk3 $id1/.

echo "greyscale pk3 is now in $id1"
