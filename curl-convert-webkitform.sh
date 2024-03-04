#!/bin/bash

filename="test.txt"

command=$(cat "$filename")

if [ $(grep -c 'WebKitFormBoundary' "$filename") -gt 0 ];then
  shortcommand=$(echo "$command"|grep -v --color=never 'WebKitFormBoundary')
  fields=$(echo "$command"|sed -ne 's/WebKitFormBoundary/\n/gp' |sed -ne 's/.*form-data; name="\([^"]\+\)".*\\r\\n\\r\\n\(.*\)\\r\\n.*$/-F '"'"'\1=\2'"'"'/gp'|sed 's/\\"/\"/g'|tr '\n' ' ')
else
  shortcommand=$(echo "$command"|sed -e 's/--data-binary.*/\n/g')
  command=$(echo "$command"|sed -e 's/.*--data-binary/\n/g'|sed -e 's/\([-]\+\)[0-9]\+\\r\\n/\1WebKitFormBoundary\\r\\n/g'|sed -e 's/\\r\\n[-]\+[0-9]\+[-]\+//g')
  fields=$(echo "$command"|sed -ne 's/WebKitFormBoundary/\n/gp' |sed -ne 's/.*form-data; name="\([^"]\+\)"[^\r\n]*\\r\\n\(.*\)\\r\\n.*/-F '"'"'\1=\2'"'"'/gp'|sed 's/\\"/\"/g'|tr '\n' ' ')
fi

echo "$shortcommand $fields" | sed 's/\\$//g' |tr '\n' ' '

