#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

delimiter="\t"

tempdir="/tmp/quakeservers_info"
mkdir -p "$tempdir"

#uses the following programs
uses="quakestat nc sort jq"

#test for needed programs
for program in $uses;do
  if ! hash $program 2>/dev/null;then
    echo "$program not installed.  bailing out."
    exit 1
  fi
done

if hash geoiplookup 2>/dev/null;then
	lookup=1
	lookuptext="location${delimiter}"
else
	lookup=0
	lookuptext=
fi

quakestat  -R -json -u -qwm master.quakeservers.net > $tempdir/quakeservers.1&
quakestat  -R -json -u -qwm qwmaster.fodquake.net > $tempdir/quakeservers.2&
wait

/asdf

#header
echo -e "${lookuptext}host${delimiter}server${delimiter}port${delimiter}version"

for both in $(awk -F'[ ]' '{print $1 , $2}' /tmp/quakeservers.tmp.1);do
	if [ -z $server ];then
		server=$both
		continue
	fi
	if [ -z $port ];then
		port=$both
	fi
	if [ ! -z "$server" ] && [ ! -z "$port" ];then
		(
			output=$(echo -e "\xff\xff\xff\xffstatus 23" | nc -w 5 -u $server $port 2>/dev/null|head -n1|tr -d "\t"|strings)
			host=$(echo "$output"|awk -F'hostname' '{print $2}'|awk -F'\' '{print $2}')
			version=$(echo "$output"|awk -F'version' '{print $2}'|awk -F'\' '{print $2}')
			if [ ! -z "$host" ];then
				locationoutput=
				if [ $lookup -eq 1 ];then
					location=$(geoiplookup $server|awk -F': ' '{print $2}')
					if [ ! -z "$location" ];then
						locationoutput="${location}"
					else
						locationoutput="N/A"
					fi
				fi
				echo -e "${locationoutput}${delimiter}${host}${delimiter}${server}${delimiter}${port}${delimiter}${version}"
			fi
		)&
		server=""
		port=""
	fi
	sleep .01
done | sort

wait
