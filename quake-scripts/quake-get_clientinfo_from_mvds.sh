#!/bin/bash
#output clientinfo from mvds

#get all user information from mvds
find . -name '*.mvd' -print0|xargs -0 -r -P$(nproc) -I % bash -c '
file="%"
grep -H --color=never -iEa "\\\\\*client\\\\" "%"|sed "s,\\\\*client\\\\,\n\\\\*client\\\\,g"| \
while IFS=$'\0' read -r -d "" line; do
    line=$(echo -n "$line"|grep  --color=never -ia "^\\\\\*client"|tr -cd "[:print:]\n")
    if [ ! -z "$line" ];then
        echo "$file : $line"
    fi
done
'
