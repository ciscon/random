#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

if [ -z $1 ];then
	read -p "version (eg 128): " version
else
	version=$1
fi

npx @puppeteer/browsers --path="$browser_path" install chrome@${version}
if [[ "$(uname)" == *"inux" ]];then
	browser=$(ls "$browser_path/chrome/"*"-${version}"*"/chrome-"*"/chrome"|tail -n1)
else
	browser=$(ls "$browser_path/chrome/mac_"*"-${version}"*"/chrome-"*"/Google Chrome "*".app/Contents/MacOS/Google Chrome"*|tail -n1)
fi
ln -sf "$browser" "$HOME/Desktop/chrome-${version}"
"$browser"
