#!/bin/bash
#output csv of git log, one line for each file/commit combination

begin_date="2012-1-29"
end_date="2014-4-29"

echo "file_change_type,filename,commit,author,date,description,patch_overview"

gitcsv=$(git log --before=$end_date --after=$begin_date --no-merges --name-status --pretty=format:'%H,%an,%ad,"%s"'|tr '\t' ',')

declare -a commitarray

bigcount=0

echo "$gitcsv"|while read line;do

  if [ -z "$line" ];then

    count=1
    commit=`echo "${commitarray[0]}"|cut -d, -f1`

    while [ $count -lt ${#commitarray[@]} ];do

      filename=`echo "${commitarray[$count]}"|cut -d, -f2`
      diff=`git diff --no-color ${commit} ${commit}^ -- "${filename}"|grep '^@@'|sed -n 's/^.*@@.*-\(.*\) +\(.*\) @@.*$/-\1 +\2/p'|tr '\n' '|'`

      if [ -z "$diff" ];then
        diff="Binary Changes."
      fi

      echo "${commitarray[$count]},${commitarray[0]},\"${diff}\""

      let count=count+1

    done

    commitarray=()
    bigcount=0


  else

    commitarray[$bigcount]="$line"
    let bigcount=bigcount+1

  fi


done|sed 's/|"$/"/'
