#!/bin/bash
#find case mismatches between con file references and files

if ! hash nproc || ! hash grep || ! hash find || ! hash rename || ! hash sed || ! hash xargs ;then
  echo "missing required binary, bailing out."
  exit 1
fi

con_files="$(find . -type f -iname '*.con' -printf '%P\t')"
if [ -z "$con_files" ];then
  echo "no con files found, are we inside the proper directory?  bailing out."
  exit 2
fi

#first fix all art files
find . -type f -iname '*.art' -print0|xargs -0 rename 's/(.*)\/([^\/]*)/$1\/\L$2/'

files="$(find . -type f -printf '%P\t')"
basename_files="$(find . -type f -printf '%f\t')"
OLD_IFS=$IFS
IFS=$'\t'

for con in $con_files;do
  (
  #first check/fix only filenames
  for file in $basename_files;do
    found=$(grep --color=never -o -i "\s$file\s" "$con"|tr '\n' '\t')
    if [ ! -z "$found" ];then
      for foundfile in $found;do
        grep --color=never "\s$file\s" "$con" >/dev/null 2>&1
        if [ $? -ne 0 ];then
          echo "case mismatch file/path on $file in $con"
          #optionally add rename or sed logic here
          sed -i "s|$foundfile| $file |g" "$con"
        fi
      done
    fi
  done

  #now entire paths
  for file in $files;do
    found=$(grep --color=never -o -i "\s$file\s" "$con"|tr '\n' '\t')
    if [ ! -z "$found" ];then
      for foundfile in $found;do
        grep --color=never "\s$file\s" "$con" >/dev/null 2>&1
        if [ $? -ne 0 ];then
          echo "case mismatch file/path on $file in $con"
          #optionally add rename or sed logic here
          sed -i "s|$foundfile| $file |g" "$con"
        fi
      done
    fi
  done
  )&
  if (( $(wc -w <<<$(jobs -p)) % $(nproc) == 0 )); then wait; fi

done

wait

IFS=$OLD_IFS
