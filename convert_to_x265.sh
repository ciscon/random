#!/bin/bash
#recursively convert videos to x265

postpend="-ciscon-x265"
preset="veryslow"
crf=18

let procs=$(nproc)-$(nproc)/2

deps="ffmpeg find file nice"
for dep in $deps;do
	if ! hash $dep >/dev/null 2>&1;then
		echo "missing dep $dep, bailing out."
		exit 1
	fi
done

OLDIFS=$IFS
IFS=$'\n'

for file in $(find . -type f);do
	dir=$(dirname "$file")
	origfile=$(basename "$file")
	if [[ $(file --mime-type -b "$file") =~ ^video ]];then
		if [[ $origfile =~ $postpend ]];then
			echo "converted file $file as input, continuing"
			continue
		fi
		mkdir -p "./x265-output/${dir}"
		base=${origfile%.*}
		output="./x265-output/${dir}/${base}${postpend}.mkv"
		if [ -e "$output" ];then
			echo "checking integrity of found output file: $output ..."
			outputcheck=$(ffmpeg -v error -i "$output" -c copy -f null - 2>&1|grep --color=never -v 'non monotonically increasing'|wc -l)
			if [ $outputcheck -eq 0 ];then
				echo "no errors found in file, checking times."
				resulttime=$(ffprobe -i "$output" -show_entries format=duration -v quiet -of csv="p=0"| cut -f1 -d".")
				originaltime=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0"| cut -f1 -d".")
				[[ $resulttime == ?(-)+([[:digit:]]) ]] || resulttime=0
				[[ $originaltime == ?(-)+([[:digit:]]) ]] || originaltime=0
				if [ $resulttime -ge $(($originaltime-1)) ] && [ $resulttime -le $(($originaltime+1)) ];then
					echo "length of input and output videos match, continuing."
					continue
				else
					echo "lengths do not match- input: $originaltime output: $resulttime"
				fi
			fi
		fi
		echo "creating $output ..."
		nice -n 20 ffmpeg -v quiet -err_detect ignore_err -i "$file" -map 0 -c:s copy -c:v libx265 -preset $preset -x265-params crf=$crf:pools=$procs -c:a copy "$output" -y
	fi
done

IFS=$OLDIFS
echo "complete"
