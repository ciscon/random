#!/bin/bash
#assumes mysql directory is named mysql.X where X is the instance number

mysqldir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
mysqlbase="$(basename $mysqldir)"
let port=3306+$(echo "${mysqlbase#*.}")
pidfile="/run/$mysqlbase/mysqld.pid"

if [ -f "$pidfile" ];then
	if kill -0 $(cat "$pidfile");then
		echo "$mysqlbase daemon already running.  exiting."
		exit 1
	fi
fi

mkdir -m 1777 -p /run/$mysqlbase

mysqld_safe --port=$port --datadir="$mysqldir" --pid-file="$pidfile" --socket=/run/$mysqlbase/mysqld.sock&
