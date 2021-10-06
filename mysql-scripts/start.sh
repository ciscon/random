#!/bin/bash
#assumes mysql directory is named mysql.X where X is the instance number
#if bindaddress variable is set we will use this instead of a new port

bindaddress=
mysqldir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
mysqlbase="$(basename $mysqldir)"
pidfile="/run/$mysqlbase/mysqld.pid"
errorlog="$mysqldir/mysql.err"

if [ -z "$bindaddress" ];then
	let port=3306+$(echo "${mysqlbase#*.}")
	additionalargs="--port=$port"
else
	additionalargs="--bind-address=$bindaddress"
fi

if [ -f "$pidfile" ];then
	if kill -0 $(cat "$pidfile");then
		echo "$mysqlbase daemon already running.  exiting."
		exit 1
	fi
fi

mkdir -m 1777 -p /run/$mysqlbase

mysqld_safe $additionalargs --log-error=$errorlog --datadir="$mysqldir" --pid-file="$pidfile" --socket=/run/$mysqlbase/mysqld.sock&
