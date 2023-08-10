#!/bin/bash

domain="office.domain.com"
ttl=3600
network_filter="10.10.10"
powerdnsurl="http://ns1.domain.com:8081"
port="8081"

deps="jq tr grep"
for dep in $deps;do
	if ! hash $dep >/dev/null 2>&1;then
		echo "missing dep $dep, bailing out."
		exit 1
	fi
done

vms=$(sudo qm list|tail -n +2|grep --color=never 'running')

IFS=$'\n'

for line in $vms;do
	id=$(echo "$line"|awk '{print $1}')
	name=$(echo "$line"|awk '{print $2}')
	if [ -z "$name" ];then
		continue
	fi
	netraw=$(sudo qm guest cmd $id network-get-interfaces) 2>/dev/null
	if [ ! -z "$netraw" ];then
		net=$(echo "$netraw"|jq -r '.[]|select( ."hardware-address" != null )|select ( .["ip-addresses"] != null)|{(."hardware-address"):[.["ip-addresses"]|.[]|."ip-address"]}|to_entries[] | [.key] + (.value[]|[.]) | @csv' 2>/dev/null|tr -d '"'|grep --color=never ",$network_filter")
		if [ ! -z "$net" ];then
			ip=$(echo "$net"|tail -n1|awk -F',' '{print $2}')
		else
			ip=
		fi
	fi
	if [ -z "$ip" ];then
		echo "no ip found for $name, skipping..."
		continue
	fi

	curl -q -H 'Content-Type: application/json' -X PATCH --data '{"rrsets": [ {"name": "'${name}'.'${domain}'.", "type": "A", "ttl": '${ttl}', "changetype": "REPLACE", "records": [ {"content": "'${ip}'", "disabled": false } ] } ] }' -H 'X-API-Key: 5c4f3a5e-4dd3-4f3e-89a2-95796c16542b' ${powerdnsurl}/api/v1/servers/localhost/zones/${domain}

done
