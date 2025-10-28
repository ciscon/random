#!/bin/bash
set -e

read -p "version (eg 128): " version

npx @puppeteer/browsers --path=/tmp/browsers install chrome@${version}
ln -sf "$(ls /tmp/browsers/chrome/linux-${version}*/chrome-linux64/chrome|head -n1)" "$HOME/Desktop/chrome-${version}"
/tmp/browsers/chrome/*linux-${version}*/chrome-linux64/chrome
