#!/bin/bash  
#continuously stream mp4 to rtsp (included perl server) and rtmp (remote) servers
#requires: libanyevent-perl libmoose-perl libnamespace-autoclean-perl libsocket6-perl libmoosex-getopt-perl
#debian: use debian multimedia repo for ffmpeg/libx264

stream_name="livetest"
currentpwd="$PWD"

#preset quality: slower is better
#compat with old decoders: -pix_fmt yuv420p
x264_preset="-preset fast -pix_fmt yuv420p"
#x264_preset="-preset veryfast"

#crf quality: highest=0 lowest=51 //this determines bitrate
#as of now just set to an average bitrate of ~1000k
crf="-b:v 1000k -bufsize 128k"
#crf="-crf 28"

client_listen_port="2222"
source_listen_port="2223"

ffmpeg_verbose_level="8"
buffer_size="150000"

server="192.168.1.20"

video="sample1.mp4"

#
#commands
#
rtsp_server=("./rtsp-server.pl -l0  -s $source_listen_port -c $client_listen_port --client_listen_address 0.0.0.0 --source_listen_address 0.0.0.0")

#this is the complicated part, we loop over the mp4 file and output in mpegts format with a bitstream filter to remove timestamp/pts information, without re-encoding- we then encode that into the mp4 we want from stdin and output to rtsp
transcode1="ffmpeg -v $ffmpeg_verbose_level -an -stream_loop -1 -i $video -c:v copy -an -bsf:v h264_mp4toannexb -f mpegts -"

#feed previous transcode into rtsp
transcode2="ffmpeg -v $ffmpeg_verbose_level -re -stream_loop -1 -i - -threads 0 $x264_preset $crf -c:v libx264 -an -f rtsp rtsp://localhost:$source_listen_port/$stream_name"

rtmp_stream="ffmpeg -buffer_size $buffer_size -v $ffmpeg_verbose_level -re -i rtsp://localhost:$client_listen_port/$stream_name -c:v copy -f flv -an rtmp://$server/oflaDemo/$stream_name"

anywait(){
	while [ 1 ];do
		for pid in $(echo $@); do
			if [[ ( -d /proc/$pid ) && ( -z `grep zombie /proc/$pid/status` ) ]]; then
				sleep 1
			else
				echo "pid $pid died..."
				return
			fi
		done
	done
}

while [ 1 ];do

	cd $currentpwd/rtsp-server
	$rtsp_server &
	pidof_rtsp=$!
	disown
	sleep 5 

	echo "Starting transcode..."
	cd $currentpwd
	eval "$transcode1|$transcode2" &
	pidof_transcode=$!
	disown

	sleep 5

	echo "Starting rtmp stream..."
	$rtmp_stream &
	pidof_rtmp=$!
	disown

	echo "rtsp $pidof_rtsp transcode $pidof_transcode rtmp $pidof_rtmp"
	anywait "$pidof_rtsp $pidof_transcode $pidof_rtmp"

    kill -9 $pidof_rtsp 2>/dev/null
    kill -9 $pidof_transcode 2>/dev/null
    kill -9 $pidof_rtmp 2>/dev/null

	sleep 5 

done
