#!/bin/bash
#assumes mysql directory is named mysql.X where X is the instance number

mysqldir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
mysqlbase="$(basename $mysqldir)"
pidfile="/run/$mysqlbase/mysqld.pid"

if [ -f "$pidfile" ];then
	kill $(cat "$pidfile")
else
	echo "no pidfile found.  attempting to kill process by name."
	ps aux|grep --color=never "\-\-datadir=$mysqldir"|grep --color=never -v "mysqld_safe"|grep --color=never -v grep|head -n1|awk '{print $2}'|xargs -r kill
fi
