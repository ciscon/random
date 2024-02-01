#!/bin/bash

filename="asdf.txt"

command=$(cat "$filename")

shortcommand=$(echo "$command"|grep -v --color=never 'WebKitFormBoundary')

fields=$(echo "$command"|sed -ne 's/WebKitFormBoundary/\n/gp' |sed -ne 's/.*form-data; name="\([^"]\+\)".*\\r\\n\\r\\n\(.*\)\\r\\n.*$/-F '"'"'\1=\2'"'"'/gp'|sed 's/\\"/\"/g'|tr '\n' ' ')

echo "$shortcommand $fields"

