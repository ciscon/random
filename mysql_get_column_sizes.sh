#!/bin/bash

mysql_prog="mysql -N -uusername -ppassword -h host"

db="database"

tables=$($mysql_prog $db -e 'SHOW tables;')

for table in $tables;do
    columns=$($mysql_prog $db -e "SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '$db' AND TABLE_NAME = '$table';")

    for column in $columns;do
        size=$($mysql_prog $db -e "SELECT sum(char_length(\`$column\`))/1024/1024 FROM $table")
        echo "${size}M : $table : $column"
    done
done
