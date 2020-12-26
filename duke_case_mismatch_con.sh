#!/bin/bash
#find case mismatches between con file references and files

con_files="$(find . -type f -iname *.con -print0|tr '\0' '\t')"
files="$(find . -type f -printf '%P\t'|tr '\0' '\t')"
OLD_IFS=$IFS
IFS=$'\t'

for file in $files;do
  for con in $con_files;do
    found=$(grep --color=never -i "$file" "$con")
    if [ ! -z "$found" ];then
      for foundfile in $found;do
        grep --color=never "$file" "$con" >/dev/null 2>&1
        if [ $? -ne 0 ];then
          echo "case mismatch file/path on $file in $con"
          #optionally add rename or sed logic here
        fi
      done
    fi
  done


done

IFS=$OLD_IFS
