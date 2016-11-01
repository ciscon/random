#!/bin/bash  
#continuously stream mp4 to rtsp (included perl server) and rtmp (remote) servers
#requires: libanyevent-perl libmoose-perl libnamespace-autoclean-perl libsocket6-perl libmoosex-getopt-perl
#debian: use debian multimedia repo for ffmpeg/libx264

stream_name="livetest"

#preset quality: slower is better
#compat with old decoders: -pix_fmt yuv420p
x264_preset="-preset fast -pix_fmt yuv420p"
#x264_preset="-preset veryfast"
#x264_preset="-preset slow"

#crf quality: highest=0 lowest=51 //this determines bitrate
#as of now just set to an average bitrate of ~1500k
crf="-b:v 1500k -bufsize 512k"
#crf="-crf 28"
#crf="-crf 42"

client_listen_port="2222"
source_listen_port="2223"

ffmpeg_verbose_level="8"
buffer_size="150000"

server="192.168.1.20"
#video="small.mp4"
video="Deakins\ Day\ 10\ mins.mp4"

rtsp_server=("cd $PWD/rtsp-server;./rtsp-server.pl -l0  -s $source_listen_port -c $client_listen_port --client_listen_address 0.0.0.0 --source_listen_address 0.0.0.0")
#this is the complicated part, we loop over the mp4 file and output in mpegts format with a bitstream filter to remove timestamp/pts information, without re-encoding- we then encode that into the mp4 we want from stdin and output to rtsp
transcode=("cd $PWD;ffmpeg -v $ffmpeg_verbose_level -an -stream_loop -1 -i $video -c:v copy -an -bsf:v h264_mp4toannexb -f mpegts -|ffmpeg -v $ffmpeg_verbose_level -re -stream_loop -1 -i - -threads 0 $x264_preset $crf -c:v libx264 -an -f rtsp rtsp://localhost:$source_listen_port/$stream_name")
#transcode=("cd $PWD;ffmpeg -v $ffmpeg_verbose_level -re -stream_loop -1 -i $video  -threads 0 $x264_preset $crf -c:v libx264 -an -f rtsp rtsp://localhost:$source_listen_port/$stream_name")
rtmp_stream=($"ffmpeg -buffer_size $buffer_size -v $ffmpeg_verbose_level -re -i rtsp://localhost:$client_listen_port/$stream_name -c:v copy -f flv -an rtmp://$server/oflaDemo/$stream_name")


while [ 1 ];do

	eval "${rtsp_server[@]}" &
	pidof_rtsp=$!
	disown

	sleep 2 

	echo "Starting transcode..."
	eval "${transcode[@]}" &
	pidof_transcode=$!

	sleep 5

	echo "Starting rtmp stream..."
	eval "${rtmp_stream[@]}"&
	pidof_rtmp=$?

	wait

	kill -9 $pidof_rtsp
	kill -9 $pidof_rtmp
	kill -9 $pidof_transcode

	sleep 2

done

#normal exit

kill -9 $pidof_rtsp
kill -9 $pidof_rtmp
kill -9 $pidof_transcode

cd $PWD
