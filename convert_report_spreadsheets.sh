#!/bin/bash
#convert all xlsx files within input directory to html files
#for now this assumes the file names/directory paths do not have spaces in them

#current day
read mon day year < <(date "+%b %_d %Y")

#specify offset if we're not running on the day specified on the worksheet
#read mon day year < <(date -d "-4 days" "+%b %_d %Y")

#properly formatted date
newdate="$mon $day $year"

inputdir=/tmp/report_conversion_input
convertdir=/tmp/report_conversion_output
finaldir=$convertdir/final

if [ ! -d $inputdir ];then
  echo "input directory $inputdir doesn't exist, exiting."
  exit
fi

if [ -d $convertdir ];then
  rm -rf $convertdir
  mkdir -p $finaldir
fi

count=0

for xlsx in $inputdir/*.xlsx;do

let count=count+1
mkdir -p $convertdir/$count

#step 1
echo "converting #${count} ($xlsx)"
libreoffice --convert-to html --outdir $convertdir/$count "$xlsx" >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo "conversion failed!"
else
  #step 2
  sed -n "/<em>$newdate<\/em>/,/<!-- \*\*\*\*\*\*\*/p" $convertdir/$count/*.html > $finaldir/$count.html 
fi

done

echo "conversions complete, `ls -l $finaldir/*.html|wc -l` result(s) in $finaldir"
