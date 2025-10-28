#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

read -p "version (eg 128.0): " version

npx @puppeteer/browsers --path="$browser_path" install firefox@stable_${version}
browser=$(ls "$browser_path/firefox/linux-stable_${version}"*"/firefox/firefox"|head -n1)
ln -sf "$browser" "$HOME/Desktop/firefox-${version}"
"$browser"
