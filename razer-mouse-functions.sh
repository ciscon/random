#razer mouse functions
if ls /sys/module/razermouse/drivers/hid:razermouse/*/device_mode > /dev/null 2>&1;then
	function razer-dpi(){
		if [ ! -z "$1" ];then
			hex=$(printf "%04x" "$1")
			echo -en "\x${hex:0:2}\x${hex:2:4}"|sudo tee /sys/module/razermouse/drivers/hid:razermouse/*/dpi >/dev/null 2>&1
			if [ $? -ne 0 ];then
				echo "setting dpi failed."
			else
				echo "dpi set to $(cat /sys/module/razermouse/drivers/hid:razermouse/*/dpi)."
				echo "$1" > ${HOME}/.razer_dpi
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
				echo "$1" > ${HOME}/.razer_rate
			fi
		fi
	}
	function razer-mode(){
		if [ "$1" = "1" ];then
			echo -n -e "\x03\x00"|sudo tee /sys/module/razermouse/drivers/hid:razermouse/*/device_mode >/dev/null
		else
			echo -n -e "\x00\x00"|sudo tee /sys/module/razermouse/drivers/hid:razermouse/*/device_mode >/dev/null
			echo "$1" > ${HOME}/.razer_mode
		fi
	}
fi
