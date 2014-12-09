#!/bin/bash
#output csv of git log, one line for each file/commit combination
#dg

begin_date="2012-1-29"
end_date="2014-4-29"

echo "filename,file_change_type,commit,author,date,description"

gitcsv=$(git log --before=$end_date --after=$begin_date --no-merges --name-status --pretty=format:'%H,%an,%ad,"%s"'|tr '\t' ',')

declare -a commitarray

bigcount=0

echo "$gitcsv"|while read line;do

  if [ -z "$line" ];then

    count=1

    while [ $count -lt ${#commitarray[@]} ];do

      echo "${commitarray[$count]},${commitarray[0]}"

      let count=count+1

    done

    commitarray=()
    bigcount=0


  else

    commitarray[$bigcount]="$line"
    let bigcount=bigcount+1

  fi


done
