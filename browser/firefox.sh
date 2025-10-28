#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

if [ -z $1 ];then
  read -p "version (eg 128.0): " version
else
  version=$1
fi

npx @puppeteer/browsers --path="$browser_path" install firefox@stable_${version}
browser=$(ls "$browser_path/firefox/"*"-stable_${version}"*"/firefox/firefox"|tail -n1)
ln -sf "$browser" "$HOME/Desktop/firefox-${version}"
"$browser"
