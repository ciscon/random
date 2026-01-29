#!/bin/bash

host='ncsphkjfominimxztjip.supabase.co'
apikey='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jc3Boa2pmb21pbmlteHp0amlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTY5Mzg1NjMsImV4cCI6MjAxMjUxNDU2M30.NN6hjlEW-qB4Og9hWAVlgvUdwrbBO13s8OkAJuBGVbo'

tmpfile='/tmp/hubstats.json'
chunksize=1000
rm -f "$tmpfile"

i=0
while [ $i -lt 1000 ];do
	let mult=$i*${chunksize}
	echo $mult 1>&2
	output=$(curl --compressed -s "https://${host}/rest/v1/v1_games?order=id.asc&select=id%2Cmap&offset=${mult}&limit=${chunksize}" -H "apikey: $apikey")
	length=$(echo "$output"|jq '. | length')
	if [ "$length" == "0" ];then break;fi
	echo "$output" >> "$tmpfile"
	let i=i+1
done

#parse maps
cat "$tmpfile"|jq -r '.[].map'|sort -u
