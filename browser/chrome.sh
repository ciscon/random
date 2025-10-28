#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

read -p "version (eg 128): " version

npx @puppeteer/browsers --path="$browser_path" install chrome@${version}
browser=$(ls "$browser_path/chrome/linux-${version}"*"/chrome-linux64/chrome"|head -n1)
ln -sf "$browser" "$HOME/Desktop/chrome-${version}"
"$browser"
