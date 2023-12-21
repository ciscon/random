#!/bin/bash

searchUser="player"
waitTime=60

deps="wget jq notify-send"
for dep in $deps;do
    if ! hash $dep >/dev/null 2>&1;then
        echo "missing dep $dep, bailing out."
        exit 1
    fi
done

while [ 1 ];do
  found=$(wget -q -O - 'https://badplace.eu/api/v2/serverbrowser/busy'| \
      jq '.[] as $parent | $parent.Players[].Name | select(. == "'$searchUser'") | $parent.Address')
  if [ "$lastfound" != "$found" ] && [ ! -z "$found" ];then
    notify-send "$searchUser on $found"
  fi
  lastfound=$found
  sleep $waitTime
done
