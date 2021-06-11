#!/bin/bash

searchUser="player"

wget -O - 'https://badplace.eu/api/v2/serverbrowser/busy'| \
    jq '.[] as $parent | $parent.Players[].Name | select(. == "'$searchUser'") | $parent.Address'
