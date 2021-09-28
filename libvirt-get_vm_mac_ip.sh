#!/bin/bash 
# ssh to libvirt hosts and retrieve mac/ip addresses for all vms

#vm network prefix
network_prefix="10.10.10"

#vm hosts
hosts="
vm-host4
vm-host5
vm-host6
"
#host to ssh into to do arp resolution, must be on same network as vms
proxy_host="dalek"

for i in $hosts;do
    if [ ! -z "$i" ];then

        vms=$(ssh "$i" "bash -c '
			vms=\$(virsh --connect qemu:///system list --name) && \
			for vm in \$vms;do
				mac=\$(virsh --connect qemu:///system domiflist \"\$vm\"|grep --color=never vnet|head -n1|awk \"{print \\\$5}\")
				if [ -z \"\$mac\" ];then 
					mac=\"NOTFOUND\" 
				fi
				echo \"\$vm \$mac\" 
			done
			'") 2>/dev/null

        if [ -z "$vms" ];then
            errors+="failed to retrieve vm list from $i."
        fi

        host=${proxy_host:-$i}

		#ssh into host and get ips
		echo "$vms"|ssh "$host" '

		#populate arp table on host
		for ip in '${network_prefix}'.{1..254}; do ping -W1 -c1 \${ip} >/dev/null 2>&1 & done;wait

		#get ips from arp table
		while read line;do
		(
            if [ ! -z "$line" ];then
				IFS=" " read name mac <<< $(echo "$line")
                    ip=$(PATH=$PATH:/usr/sbin:/sbin arp -n|grep --color=never -i "$mac" 2>/dev/null|cut -d " " -f1|tail -n1 2>/dev/null)
                    if [ -z "$ip" ];then
						ip="NOTFOUND"
						os="NOTFOUND"
					else
						#check ip for port 22
						if hash nc;then 2>/dev/null
							os=$(echo "garbage"|nc -w 1 $ip 22 >/dev/null 2>&1&&echo lin||echo win)
						fi
					fi
                    echo -e "'$i'\t$name\t$ip\t$mac\t$os"
            fi
		)&
        done'
    fi
done

if [ ! -z "$errors" ];then
    echo -e "\nerrors:\n$errors" 1>&2
fi
