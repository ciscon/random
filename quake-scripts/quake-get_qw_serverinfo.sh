#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

delimiter=","

quakestatoptions=""

#if using mmdblookup, location of db
mmdblocation="/var/lib/GeoIP/GeoLite2-Country.mmdb"

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

lookuptext="location${delimiter}"
if hash geoiplookup 2>/dev/null;then
	lookup=1
elif hash mmdblookup 2>/dev/null;then
	lookup=2
else
	lookup=0
	lookuptext=
fi

quakestat $quakestatoptions -R -json -u -qwm master.quakeservers.net > $tempdir/quakeservers.1&
quakestat $quakestatoptions -R -json -u -qwm qwmaster.fodquake.net > $tempdir/quakeservers.2&
quakestat $quakestatoptions -R -json -u -qwm master.quakeworld.nu > $tempdir/quakeservers.3&
wait

jq -r 'to_entries[].value|[.address, .name, .rules."*version", .rules."*admin", .gametype]|@csv' $tempdir/quakeservers.[0-9]|sort -u > $tempdir/quakeservers.csv

#header
echo -e "${lookuptext}hostandport${delimiter}servername${delimiter}version${delimiter}admin${delimiter}gametype${delimiter}host${delimiter}port"

while IFS= read -r line;do
echo "$line"|while IFS="$delimiter" read -r hostname name version;do
	if [ -z "$hostname" ] || [ -z "$version" ];then
		continue
	fi

	server=$(echo "$hostname"|awk -F':' '{print $1}'|tr -d '"')
	port=$(echo "$hostname"|awk -F':' '{print $2}'|tr -d '"')

	if [ ! -z "$server" ] && [ ! -z "$port" ];then
		locationoutput=
		if [ $lookup -gt 0 ];then
			if [ $lookup -eq 1 ];then
				location=$(geoiplookup $server|awk -F': ' '{print $2}')
			else
				location=$(mmdblookup --file $mmdblocation --ip $server country iso_code 2>/dev/null|tr -d '\n'|awk -F'"' '{print $2}')
			fi
			if [ ! -z "$location" ];then
				locationoutput="${location}"
			else
				locationoutput="N/A"
			fi
			locationoutput+=$delimiter
		fi
		echo -e "${locationoutput}${line}${delimiter}${server}${delimiter}${port}"
		server=""
		port=""
	fi
done
done < $tempdir/quakeservers.csv
