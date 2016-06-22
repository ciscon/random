#!/bin/bash
#convert text/command to ascii numbers - example of why scrubbing scripts isn't quite good enough
#to run: eval $'outputofcommand'

string="while [ 1 ];do echo \"don't run random shit you copied off the internet in your terminal!\";done"

echo "$string"|sed 's/\(.\)/\1\n/g'|while read i;do if [ -z "$i" ];then i=" ";fi;printf "\\%o" "'${i}";done;echo ""
