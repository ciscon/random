#!/bin/bash
#pivot data, repeat first two columns in new rows (even if empty) until changed, pivot the rest of the columns (dates) with cell data

#convert to csv first?
#ssconvert input.xlsx twitter.csv

input_file="twitter.csv"

date_array=($(head -n1 $input_file|tr ',' '\t'|cut -f3-))

count=0

tail -n+2 $input_file|tr ',' '|'|while read line;do 

IFS=$'|'

colcount=0
for col in $line;do

    if [ $colcount -eq 0 ];then
        tmpname=$col
    elif [ $colcount -eq 1 ];then
        tmptag=$col
    else

        if [ ! -z $tmpname ];then
            name=$(echo $tmpname|tr -d ' '|tr -d '"')
        fi
        if [ ! -z $tmptag ];then
            tag=$tmptag
        fi

        if [ ! -z ${col} ];then
            if [ ! -z ${name} ] && [ ! -z ${tag} ];then
                let datenum=colcount-2

                echo -e "$name,$tag,${date_array[$datenum]} ${col}"
            fi
        fi
    fi

    let colcount=colcount+1

done

let count=count+1

done
