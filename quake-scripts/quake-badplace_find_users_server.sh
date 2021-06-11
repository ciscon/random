#!/bin/bash

searchUser="player"
waitTime=60

while [ 1 ];do
  found=$(wget -q -O - 'https://badplace.eu/api/v2/serverbrowser/busy'| \
      jq '.[] as $parent | $parent.Players[].Name | select(. == "'$searchUser'") | $parent.Address')
  if [ "$lastfound" != "$found" ];then
    notify-send "$searchUser on $found"
  fi
  lastfound=$found
  sleep $waitTime
done
