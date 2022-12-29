#!/bin/bash

function razer-dpi(){
	if [ ! -z "$1" ];then
		hex=$(printf "%04x" "$1")
		echo -en "\x${hex:0:2}\x${hex:2:4}"|sudo tee /sys/module/razermouse/drivers/hid:razermouse/*/dpi >/dev/null
		if [ $? -ne 0 ];then
			echo "setting dpi failed."
		else
			echo "dpi set to $(cat /sys/module/razermouse/drivers/hid:razermouse/*/dpi)."
		fi
	fi
}

function razer-rate(){
	if [ ! -z "$1" ];then
		echo -en "$1"|sudo tee /sys/module/razermouse/drivers/hid:razermouse/*/poll_rate >/dev/null
		if [ $? -ne 0 ];then                                                                                                               
			echo "setting polling rate failed."
		else
			echo "polling rate set to $(cat /sys/module/razermouse/drivers/hid:razermouse/*/poll_rate)."
		fi
	fi
}
