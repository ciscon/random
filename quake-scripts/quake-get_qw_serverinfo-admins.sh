#!/bin/bash
# poll individual quake servers and get admin information, output in csv format

tempdir="/tmp/quakeservers_info"
mkdir -p "$tempdir"

deps="jq quakestat sed sort"
for dep in $deps;do
    if ! hash $dep >/dev/null 2>&1;then
        echo "missing dep $dep, bailing out."
        exit 1
    fi
done

quakestat  -R -json -u -qwm master.quakeservers.net > $tempdir/quakeservers.1&
quakestat  -R -json -u -qwm qwmaster.fodquake.net > $tempdir/quakeservers.2&
wait

declare -A admins

jq -r 'to_entries[].value|[.rules."*admin", .rules."*version", .hostname]|@tsv' $tempdir/quakeservers.[0-9]|sort -u > $tempdir/quakeservers.csv

while IFS=$'\t' read adminfull version hostname;do

	if [ -z "$hostname" ];then
		continue
	fi
    adminemail=$(echo "$adminfull"|awk -F '[<>]' '{print $2}'|sed 's/\[at\]/@/g')
    admin=$(echo "$adminfull"|awk -F '[<>]' '{print $1}'|awk '{$1=$1};1'|sed 's/\[at\]/@/g')

    key="$adminemail"

    if [ -z "$admin" ];then
        admin="$adminemail"
    fi
    if [ -z "$adminemail" ];then
        if echo "$admin"|grep -e '@' >/dev/null 2>&1;then
            adminemail=$(echo "$admin"|rev | cut -d' ' -f 1 | rev)
        fi
    fi
    if [ -z "$adminemail" ];then
        adminemail="$admin"
        key="$admin"
    fi
    if [ ! -z "$key" ];then
        #omitting server (ip) for now
        admins[$key]="$hostname\t$version\t$admin\t$adminemail"
    fi

done < $tempdir/quakeservers.csv

echo -e "server\tversion\tadmin\tcontact"

for adminline in "${!admins[@]}";do
    echo -e ${admins[$adminline]}
done
