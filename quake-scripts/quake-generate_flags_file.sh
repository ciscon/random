#!/bin/bash

tempdir="/tmp/quakeflags"
pngsize="115x"

rm -rf "$tempdir"

mkdir -p "${tempdir}/textures/scoreboard/flags"
echo "[" > "${tempdir}/textures/scoreboard/flags.json"

contents=''

#iso 3166-1
while read na url name
do

	echo "$name"
	lower=$(echo $name|tr '[:upper:]' '[:lower:]')
	urlsvg=$(echo "${url%.png}"| sed 's/\(.*\)*\/.*px.*/\1/g;s/\/thumb//g'  )
	curl -s "$urlsvg" > "${tempdir}/textures/scoreboard/flags/${lower}.${urlsvg##*.}"
	convert -resize $pngsize "${tempdir}/textures/scoreboard/flags/${lower}.${urlsvg##*.}" -normalize "${tempdir}/textures/scoreboard/flags/${lower}.png"
	pngquant --ext .png --force "${tempdir}/textures/scoreboard/flags/${lower}.png"
	rm -f "${tempdir}/textures/scoreboard/flags/${lower}.${urlsvg##*.}"
	contents+=$(echo -e '{ "code": "'${lower}'", "file": "flags/'${lower}'.png" },')
	country=$name

	#iso 3166-2
	while read na name url
	do

		echo "$name"
	    lower=$(echo $name|tr '[:upper:]' '[:lower:]')
		if [ -f "${tempdir}/textures/scoreboard/flags/${lower}.svg" ];then continue;fi
	    urlsvg=$(echo "${url%.png}"| sed 's/\(.*\)*\/.*px.*/\1/g;s/\/thumb//g')
	    curl -s "$urlsvg" > "${tempdir}/textures/scoreboard/flags/${lower}."${urlsvg##*.}""
	    convert -resize $pngsize "${tempdir}/textures/scoreboard/flags/${lower}.${urlsvg##*.}" -normalize "${tempdir}/textures/scoreboard/flags/${lower}.png"
	    pngquant --ext .png --force "${tempdir}/textures/scoreboard/flags/${lower}.png"
	    rm -f "${tempdir}/textures/scoreboard/flags/${lower}.${urlsvg##*.}"
	    contents+=$(echo -e '{ "code": "'${lower}'", "file": "flags/'${lower}'.png" },')
	done < <(curl -s https://en.wikipedia.org/wiki/ISO_3166-2:$country|tr -d '\n'|sed 's/<span class="monospaced">'$country'-/\n|||'$country'-/g'|grep --color=never '^|||'|sed 's/|||\('$country'-[A-Z0-9]*\).*src="\/\/upload\([^"]*\)".*/flag \1 https:\/\/upload\2/g'|grep --color=never '^flag')

done < <(curl -s https://en.wikipedia.org/wiki/ISO_3166-1|tr -d '\n'|sed 's/flagicon/\n|||/g'|grep --color=never '^|||'|sed 's/.*alt="" src="\([^"]*\)\".*ISO 3166-2:\([^"]*\)">.*/flag https:\1 \2 /g'|grep '^flag' --color=never)

echo -e "${contents::-1}\n]" >> "${tempdir}/textures/scoreboard/flags.json"

cd "$tempdir"
zip -9 -r allflags.pk3 *
