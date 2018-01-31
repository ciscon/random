#!/bin/bash
#fix duplicate port numbers in hdfs storage location for hive tables and underlying partitions

hive_host="ss-cdh-8:10000"

hive_command="beeline --color=false --showHeader=false --fastConnect=true --verbose=false --showWarnings=false --showNestedErrs=false --silent=true --outputformat=tsv -u jdbc:hive2://$hive_host/ -e "


for table in $(impala-shell -B -q 'show tables' 2>/dev/null);do

    echo "updating table $table"

    location=$($hive_command "describe formatted $table"|grep ^\'Location:|awk -F'\t' '{print $2}'|tr -d \')
    newlocation=$(echo $location|sed 's/8020:8020/8020/g')

    if [ ! -z "$newlocation" ];then
        $hive_command "alter table $table set location '$newlocation'"

        echo "updated table $table"

        #fix individual partisions as well
        partitions=$($hive_command "show partitions $table;" 2>/dev/null|tr -d \')
        if [ ! -z "$partitions" ];then

            echo "updating partitions for table $table"

            for part in $partitions;do
                $hive_command "alter table $table partition ($(echo "$part"|tr '/' ',')) set location '${newlocation}/$part'";
            done

            echo "updated partitions for table $table"
        fi

    fi

done

wait
