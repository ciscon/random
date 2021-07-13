file="example.swf"
count=0
for i in $(swfmill swf2xml "$file"|grep --color=never DefineSound -A2|sed -n 's,.*<data>\(.*\)</data>.*,\1,p');do
    let count=count+1
    echo "${i}"|base64 -d > $(basename $file)-${count}.mp3
done                                                                                                
