#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

if [ -z $1 ];then
	read -p "version (eg 128): " version
else
	version=$1
fi

npx @puppeteer/browsers --path="$browser_path" install chrome@${version}
browser=$(ls "$browser_path/chrome/"*"-${version}"*"/chrome-"*"/chrome"|tail -n1)
ln -sf "$browser" "$HOME/Desktop/chrome-${version}"
"$browser"
