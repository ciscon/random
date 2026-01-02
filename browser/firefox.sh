#!/bin/bash
set -e

browser_path="/var/tmp/browsers"

if [ -z $1 ];then
	read -p "version (eg 128.0): " version
else
	version=$1
fi

policy_json='{
  "policies": {
    "DisableAppUpdate": true
  }
}'

npx @puppeteer/browsers --path="$browser_path" install firefox@stable_${version}
if [[ "$(uname)" == *"inux" ]];then
	browser=$(ls "$browser_path/firefox/"*"-stable_${version}"*"/firefox/firefox"|tail -n1)
else
	browser=$(ls "$browser_path/firefox/"*"-stable_${version}"*"/Firefox.app/Contents/MacOS/firefox")
fi
browser_installed_dir=$(dirname "${browser}")
echo disabled > "${browser_installed_dir}/update-settings.ini"
mkdir -p "${browser_installed_dir}/distribution"
echo "$policy_json" > "${browser_installed_dir}/distribution/policies.json"
ln -sf "$browser" "$HOME/Desktop/firefox-${version}"
"$browser"
