#!/bin/bash
#check quake ports for usage

ports=$(grep --color=never '^qtv ' /opt/qtv/qtv.cfg | awk '{print $2}')

populated=0

for port in $ports;do
        tempop=$(quakestat -raw ',' -qws $port|awk -F',' '{print $6}')
        if [ ! -z "$temppop" ];then
                let populated=populated+temppop
        fi
done

if [ $populated -gt 0 ];then
        echo "populated: $populated - exiting."
        exit 0
fi
