#!/bin/bash

#example output parsing: parse output into relevent fields example: jq '.[] | {iid, web_url, title, description}'
	#csv output: jq 'reduce inputs as $in (.; . + $in)|.[]|{iid, web_url, title}'|jq -sr '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[. // empty])) as $rows | $cols, $rows[] | @csv'


gitlab_token=""
gitlab_url="https://gitlab.example.com/api/v4/projects/2"


if [ -z $1 ] || [ -z $2 ];then
	echo "usage: $(basename "$0") previous_release_tag current_release_tag"
	exit 0
fi

#doing it with the repository
#export GIT_DIR=/home/git/sitscape/dev_lamp/.git
#gitoutput=$(git log --merges --pretty=format:"%s" ${1}..${2}|grep "Merge branch '.*' into"|grep -v -e "remote-tracking branch" -e "'release'.*into" -e "'staging'.*into" -e "'dev'.*into" -e "into .*fortify" |sed "s/Merge branch '\([^']\+\)'.*/\1/g"|sort -u)

#doing it with gitlab api
gitoutput=$(
	curl --compressed -s -H "Content-Type: application/json" -H "PRIVATE-TOKEN: ${gitlab_token}" -L "${gitlab_url}/repository/compare?from=${1}&to=${2}"| \
		jq -r '[.commits[] | select(.parent_ids|length > 1)  ]|sort_by(.created_at)|.[]|.title' | \
		grep "Merge branch '.*' into"|grep -v -e "remote-tracking branch" -e "'release'.*into" -e "'staging'.*into" -e "'dev'.*into" -e "into .*fortify" | \
		sed "s/Merge branch '\([^']\+\)'.*/\1/g"|tr -d '"'|sort -u
)

if [ -z "$gitoutput" ];then
	echo "no merges found"
	exit 1
fi

urls=""
for i in $gitoutput;do
	if [ -z "$i" ];then
		continue
	fi
	filter="source_branch=$i"
	urls+=" ${gitlab_url}/merge_requests?${filter}"
done

output=$(curl --compressed -s -H "Content-Type: application/json" -H "PRIVATE-TOKEN: ${gitlab_token}" -L --parallel -parallel-immediate --parallel-max 20 $urls) 2>/dev/null

if [ -z "$output" ];then
	echo "no output."
	exit 2
fi

#generate proper json output
echo "$output"|jq 'reduce inputs as $in (.; . + $in)'
