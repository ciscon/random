#!/bin/bash 
# ssh to proxmox hosts and retrieve mac/ip addresses for all vms

#network filter to grab the correct address from vm config
network_filter="10."

#vm hosts
hosts="
pve1
pve2
pve3
pve4
"

deps="ssh jq tr grep"
for dep in $deps;do
  if ! hash $dep >/dev/null 2>&1;then
    echo "missing dep $dep, bailing out."
    exit 1
  fi
done

vms=
for i in $hosts;do
	if [ ! -z "$i" ];then
		(
			qm_command="ssh -oControlMaster=auto -oControlPath="$HOME/.ssh/%u:%r@%h:%p.sock" -oControlPersist=yes $i sudo qm"

			vms=$(eval $qm_command list|tail -n +2|grep --color=never 'running')

			IFS=$'\n'

			for line in $vms;do
				mac=
				ip=
				id=$(echo "$line"|awk '{print $1}')
				name=$(echo "$line"|awk '{print $2}')
				netraw=$(eval $qm_command guest cmd $id network-get-interfaces) 2>/dev/null
				if [ ! -z "$netraw" ];then
					net=$(echo "$netraw"|jq -r '.[]|select( ."hardware-address" != null )|select ( .["ip-addresses"] != null)|{(."hardware-address"):[.["ip-addresses"]|.[]|."ip-address"]}|to_entries[] | [.key] + (.value[]|[.]) | @csv' 2>/dev/null|tr -d '"'|grep --color=never ",$network_filter")
					if [ ! -z "$net" ];then
						mac=$(echo "$net"|tail -n1|awk -F',' '{print $1}')
						ip=$(echo "$net"|tail -n1|awk -F',' '{print $2}')
					fi
				fi
				mac=${mac:-NOTFOUND}
				ip=${ip:-NOTFOUND}

				hostinfo=$(eval $qm_command guest cmd $id get-osinfo 2>/dev/null)
				os=$(echo "$hostinfo"|grep --color=never '"id"'|awk -F'"' '{print $4}')
				version=$(echo "$hostinfo"|grep --color=never '"version-id"'|awk -F'"' '{print $4}')
				if [ ! -z "$version" ];then
					version="-${version}"
				fi
			  echo -e "$i\t$name\t$ip\t$mac\t$id\t${os}${version}"
			done
		)&
	fi
done

wait
