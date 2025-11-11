#!/bin/bash

#example output parsing: parse output into relevent fields example: jq '.[] | {iid, web_url, title, description}'

gitlab_token=""
gitlab_url="https://gitlab.example.com/api/v4/projects/2"


if [ -z $1 ] || [ -z $2 ];then
	echo "usage: $(basename "$0") previous_release_tag current_release_tag"
	exit 0
fi

tempdir="/tmp/gitlabmrs-output"

#doing it with the repository
#export GIT_DIR=/home/git/sitscape/dev_lamp/.git
#gitoutput=$(git log --merges --pretty=format:"%s" ${1}..${2}|grep "Merge branch '.*' into"|grep -v -e "remote-tracking branch" -e "'release'.*into" -e "'staging'.*into" -e "'dev'.*into" -e "into .*fortify" |sed "s/Merge branch '\([^']\+\)'.*/\1/g"|sort -u)

#doing it with gitlab api
gitoutput=$(
	curl -s -H "Content-Type: application/json" -H "PRIVATE-TOKEN: ${gitlab_token}" -L "${gitlab_url}/repository/compare?straight=false&from=${1}&to=${2}"| \
		jq '.commits[]|select(.parent_ids|length > 1)|.title'| \
		grep "Merge branch '.*' into"|grep -v -e "remote-tracking branch" -e "'release'.*into" -e "'staging'.*into" -e "'dev'.*into" -e "into .*fortify" | \
		sed "s/Merge branch '\([^']\+\)'.*/\1/g"|tr -d '"'|sort -u
)

if [ -z "$gitoutput" ];then
	echo "no merges found"
	exit 1
fi

#clean up temp dir
if [ -d "$tempdir" ];then
	rm -rf "$tempdir"
fi
mkdir -p "$tempdir"

for i in $gitoutput;do
	(
		if [ -z "$i" ];then
			continue
		fi
		filter="source_branch=$i"
		output=$(curl -s -H "Content-Type: application/json" -H "PRIVATE-TOKEN: ${gitlab_token}" -L "${gitlab_url}/merge_requests?${filter}" 2>/dev/null)

		if [ ! -z "$output" ];then
			echo "$output" > "${tempdir}/${i}.json"
		fi
	)&
done

wait

#combine output into single json
cat "${tempdir}/"*.json|jq 'reduce inputs as $in (.; . + $in)'
