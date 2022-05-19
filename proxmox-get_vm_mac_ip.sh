#!/bin/bash 
# ssh to proxmox hosts and retrieve mac/ip addresses for all vms

#vm network prefix
network_prefix="10.10.10."

#vm hosts
hosts="
pve1
pve2
pve3
pve4
"

vms=
for i in $hosts;do
	if [ ! -z "$i" ];then
		(
			qm_command="ssh -oControlMaster=auto -oControlPath="$HOME/.ssh/%u:%r@%h:%p.sock" -oControlPersist=yes $i sudo qm"

			vms=$(eval $qm_command list|tail -n +2|grep --color=never 'running')

			IFS=$'\n'

			for line in $vms;do
				id=$(echo "$line"|awk '{print $1}')
				name=$(echo "$line"|awk '{print $2}')

				net=$(eval $qm_command guest cmd $id network-get-interfaces 2>/dev/null|grep -B1 -A2 --color=never '"ip-addresses"'|egrep --color=never -e '"ip-address"' -e '"hardware-address"'|grep -B1 --color=never "\"$network_prefix")
				mac=$(echo "$net"|head -n1|awk -F'"' '{print $4}')
				ip=$(echo "$net"|tail -n1|awk -F'"' '{print $4}')
				hostinfo=$(eval $qm_command guest cmd $id get-osinfo 2>/dev/null)
				os=$(echo "$hostinfo"|grep --color=never '"id"'|awk -F'"' '{print $4}')
				version=$(echo "$hostinfo"|grep --color=never '"version-id"'|awk -F'"' '{print $4}')
				if [ ! -z "$version" ];then
					version="-${version}"
				fi
				if [ ! -z "$ip" ];then
					echo -e "$i\t$name\t$ip\t$mac\t$id\t${os}${version}"
				fi
			done
		)&
	fi
done|sort

wait
