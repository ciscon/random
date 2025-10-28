#!/bin/bash
set -e

read -p "version (eg 128.0): " version

npx @puppeteer/browsers --path=/tmp/browsers install firefox@stable_${version}
ln -sf "$(ls /tmp/browsers/firefox/*stable_${version}*/firefox/firefox|head -n1)" "$HOME/Desktop/chrome-${version}"
/tmp/browsers/firefox/*stable_${version}*/firefox/firefox
