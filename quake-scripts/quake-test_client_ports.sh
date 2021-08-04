#!/bin/bash
# args: host port unique
# unique defaults to 1, if you'd like to see every response set to 0

host=${1:-nicotinelounge.com}
port=${2:-27500}
unique=${3:-1}

#uses the following programs
uses="hping3 sudo awk sort bc"

#test for needed programs
for program in $uses;do
  if ! hash $program 2>/dev/null;then
    echo "$program not installed.  bailing out."
    exit 1
  fi
done

unique_arg=""
if [ "$unique" = "1" ];then
  unique_arg="u"
fi

every=5
start=27000
stop=28000

#clientport scanner
output=$(
  for clientport in $(seq $start $stop);do
    if (( $clientport % $every == 0 ));then
      echo -n "client port=$clientport ";echo -e "\xff\xff\xff\xffstatus 23"|sudo hping3 -2 $host -p $port -E /dev/stdin -d 10 -c 1 -s $clientport 2>/dev/null|grep --color=never 'rtt='
    fi
  done|awk -F'[= ]' '{print $16,":",$3}'|sort -nr${unique_arg}
)

top=$(echo "$output"|head -n1|awk '{print $1}')
bottom=$(echo "$output"|tail -n1|awk '{print $1}')
range=$(echo "${top}-${bottom}"|bc)

echo "$output"
echo "range: $range"
