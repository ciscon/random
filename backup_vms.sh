#!/bin/bash
#live backup of lvm backed vms

backup_mountpoint="/mnt/ssnas1"

#lvs of vms to backup
lvs="buildbox2-root
cdh5
oracle-root
demo-root
sharepoint
feng_office
qa-el7"

lvpath="/dev/vmvg1"


#check that backup mountpoint is mounted
mountpoint -q ${backup_mountpoint}||mount ${backup_mountpoint} >/dev/null 2>&1
mountpoint -q ${backup_mountpoint} >/dev/null 2>&1

if [ $? -ne 0 ];then
  echo "ssnas1 not mounted, exiting."
  exit 1
fi

mkdir -p ${backup_mountpoint}/vm-host2 >/dev/null 2>&1


function displaytime() {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d hours ' $H
  [[ $M > 0 ]] && printf '%d minutes ' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf 'and '
  printf '%d seconds\n' $S
}

for lv in $lvs;do

  echo "backing up $lv at `date`"
  START_TIME=`date +%s`

  lvcreate -L5G -s -n backup$lv $lvpath/$lv >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "creation of snapshot failed, exiting."
    exit 2
  fi
  
  if [ -e ${backup_mountpoint}/vm-host2/$lv ];then
    mv -f ${backup_mountpoint}/vm-host2/$lv ${backup_mountpoint}/vm-host2/${lv}.last >/dev/null 2>&1
  fi

  nice ionice -n2 dd if=$lvpath/backup$lv of=${backup_mountpoint}/vm-host2/$lv bs=32M iflag=direct oflag=direct 2>&1
  if [ $? -ne 0 ];then
    echo "backup of $lv failed, exiting."
    exit 3 
  fi
  lvremove $lvpath/backup$lv -f >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "removal of snaphot failed, exiting."
    exit 4
  fi

  END_TIME=`date +%s`
  let RUN_TIME=END_TIME-START_TIME

  echo -e "backup of $lv complete in $(displaytime $RUN_TIME)\n"

done
