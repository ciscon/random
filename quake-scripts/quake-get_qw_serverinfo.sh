#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

delimiter="\t"

tempdir="/tmp/quakeservers_info"
mkdir -p "$tempdir"

#uses the following programs
uses="quakestat sort jq awk"

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

jq -r 'to_entries[].value|[.hostname, .name, .rules."*version"]|@tsv' $tempdir/quakeservers.[0-9]|sort -u > $tempdir/quakeservers.csv

#header
echo -e "${lookuptext}host${delimiter}server${delimiter}port${delimiter}version"

while IFS=$'\t' read hostname name version;do
	if [ -z "$hostname" ] || [ -z "$version" ];then
		continue
	fi

	server=$(echo "$hostname"|awk -F':' '{print $1}')
	port=$(echo "$hostname"|awk -F':' '{print $2}')

	if [ ! -z "$server" ] && [ ! -z "$port" ];then
		locationoutput=
		if [ $lookup -eq 1 ];then
			location=$(geoiplookup $server|awk -F': ' '{print $2}')
			if [ ! -z "$location" ];then
				locationoutput="${location}"
			else
				locationoutput="N/A"
			fi
		fi
		echo -e "${locationoutput}${delimiter}${name}${delimiter}${server}${delimiter}${port}${delimiter}${version}"
		server=""
		port=""
	fi
done < $tempdir/quakeservers.csv
