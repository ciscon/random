#!/bin/bash

tempdir="/tmp/quakeflags"
rm -rf "$tempdir"

mkdir -p "${tempdir}/textures/scoreboard/flags"
echo "[" > "${tempdir}/textures/scoreboard/flags.json"
contents=''
while read na url name
do
	lower=$(echo $name|tr '[:upper:]' '[:lower:]')
	curl -s "$url" > "${tempdir}/textures/scoreboard/flags/${lower}.png"
	convert "${tempdir}/textures/scoreboard/flags/${lower}.png" "${tempdir}/textures/scoreboard/flags/${lower}.png"
	contents+=$(echo -e '{ "code": "'${lower}'", "file": "flags/'${lower}'.png" },')
done < <(curl -s https://en.wikipedia.org/wiki/ISO_3166-1|tr -d '\n'|sed 's/flagicon/\n|||/g'|grep '^|||'|sed 's/.*alt="" src="\([^"]*\)\".*ISO 3166-2:\([^"]*\)">.*/flag https:\1 \2 /g'|grep '^flag' --color=never)

echo -e "${contents::-1}\n]" >> "${tempdir}/textures/scoreboard/flags.json"

cd "$tempdir"
zip -9 -r allflags.pk3 *
