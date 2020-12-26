#!/bin/bash
#find case mismatches between con file references and files

con_files="$(find . -type f -iname *.con -printf '%P\t')"
files="$(find . -type f -printf '%P\t')"
OLD_IFS=$IFS
IFS=$'\t'

for con in $con_files;do
  (
  for file in $files;do
    found=$(grep --color=never -i "$file" "$con")
    if [ ! -z "$found" ];then
      for foundfile in $found;do
        grep --color=never "$file" "$con" >/dev/null 2>&1
        if [ $? -ne 0 ];then
          echo "case mismatch file/path on $file in $con"
          #optionally add rename or sed logic here
          #sed -i "s|$foundfile|$file|g" "$con"
        fi
      done
    fi
  done
  )&
  if (( $(wc -w <<<$(jobs -p)) % $(nproc) == 0 )); then wait; fi
done

wait

IFS=$OLD_IFS
