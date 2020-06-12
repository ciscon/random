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

        vms=$(ssh "$i" "virsh list --name") 2>/dev/null
        if [ -z "$vms" ];then
            errors+="failed to retrieve vm list from $i."
        fi
        host=${proxy_host:-$i}
        ssh "$host" "for ip in ${network_prefix}.{1..254}; do ping -W1 -c1 \${ip} >/dev/null 2>&1 & done;wait"
        for vm in $vms;do
            if [ ! -z "$vm" ];then
                (
                    mac=$(ssh "$i" "virsh domiflist \"$vm\"|grep --color=never vnet|awk '{print \$5}'" 2>/dev/null)
                    if [ -z "$mac" ];then
                        errors+="no mac found for $vm\n"
                    fi
                    ip=$(ssh "$host" "arp -n|grep --color=never -i \"$mac\" 2>/dev/null|tail -n1|awk '{print \$1}' 2>/dev/null")
                    if [ -z "$ip" ];then
                        errors+="no ip found for $vm\n"
                    else
                        echo -e "$i\t$vm\t$ip\t$mac"
                    fi
                )&
            fi
        done
    fi
done

wait

if [ ! -z "$errors" ];then
    echo -e "\nerrors:\n$errors" 1>&2
fi
