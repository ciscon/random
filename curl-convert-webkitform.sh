cat asdf.txt|sed -ne 's/WebKitFormBoundary/\n/gp' |sed -ne 's/.*; name="\([^"]\+\)".*\\r\\n\\r\\n\([^\\]*\)\\r\\n.*/-F '"'"'\1=\2'"'"'/gp'|tr '\n' ' '

