#!/bin/bash 
# simple script to get avg tx/rx of linux int using only ifconfig
# dg - 10-1-15

#which interface to poll
interface=${1-eth0}

tempfile=/tmp/check_bw_${interface}

if [ ! -e $tempfile ];then
    rxbandwidth=$(ifconfig ${interface}|grep 'RX packets'|awk -F' ' '{print $5}')
    txbandwidth=$(ifconfig ${interface}|grep 'TX packets'|awk -F' ' '{print $5}')
    bandwidth1="$rxbandwidth $txbandwidth"
    echo "$bandwidth1" > $tempfile
    date +"%s" >> $tempfile
    exit
else
    bandwidth1=$(cat $tempfile)
fi

if [ -z "$bandwidth1" ];then
    echo "Failed to get net data!"
    exit 3
fi


    rxbandwidth=$(ifconfig ${interface}|grep 'RX packets'|awk -F' ' '{print $5}')
    txbandwidth=$(ifconfig ${interface}|grep 'TX packets'|awk -F' ' '{print $5}')
    bandwidth2="$rxbandwidth $txbandwidth"


if [ -z "$bandwidth2" ];then
    echo "Failed to get net data!"
    exit 3
fi


#no bandwidth usage?
if [ "$(echo \"$bandwidth1\"|head -1)" == "$(echo \"$bandwidth2\")" ];then
    recvbps=0
    sendbps=0

else

    olddate=$(echo "${bandwidth1}"| tail -n1)
    newdate=$(date +"%s")
    secs=$(echo "${newdate}-${olddate}"|bc)


    oldrecv=$(echo "${bandwidth1}"|head -1|awk '{print $1}')
    oldsend=$(echo "${bandwidth1}"|head -1|awk '{print $2}')

    newrecv=$(echo "${bandwidth2}"|head -1|awk '{print $1}')
    newsend=$(echo "${bandwidth2}"|head -1|awk '{print $2}')

    recvbps=$(echo "((${newrecv}-${oldrecv})/${secs})/1024"|bc)
    sendbps=$(echo "((${newsend}-${oldsend})/${secs})/1024"|bc)

    #fix broken numbers
    if [ $recvbps -lt 0 ];then
        recvbps=0 
    fi

    if [ $sendbps -lt 0 ];then
        sendbps=0
    fi

fi

echo "Recv: ${recvbps}kB/sec Trans: ${sendbps}kB/sec|recvkbytes_s=${recvbps} transkbytes_s=${sendbps}"


#make new bandwidth old
echo "$bandwidth2" > $tempfile
date +"%s" >> $tempfile


exit 0
