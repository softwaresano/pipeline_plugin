#!/bin/bash
function get_pr_description() {
  [[ -z $CDN_BUILD_LIB ]] && return;
  source "${CDN_BUILD_LIB:?}/bin/github_api.sh"
  TOKEN_GITHUB=$(grep -Po '(?<=^AUTH_TOKEN=).*' "${CDN_BUILD_LIB:?}"/makefiles/conf/Telefonica_cdn.mk) \
  GITHUB_API_URL=https://api.github.com github_request 'GET' \
    "/repos/$(git config --get remote.origin.url | grep -Po '(?<=:).*(?=\.git)')/pulls/${id_pr:?}" \
    "" | grep -Po '(?<=^  "title": ").*(?=")'
}

log_message=$(git log -1 --pretty="format:%s") || exit 1
id_pr=$(echo "${log_message:?}"|grep -Po '(?<=^Merge pull request #).*(?= from )') || exit 0
item=$(echo "${log_message:?}"|cut -d'/' -f2-)
[ -z $DP_HOME ] && export DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/../../../../../)
source "${DP_HOME:?}"/profiles/publish/rpm/dp_publish.sh
version=$(dp_version.sh)
filename="$(dirname "$(get_repo_dir)")/release-notes-$version.txt"
pr_url="https://github.com/$(dp_scm_url.sh |grep -Po '(?<=^git@github.com:).*(?=\.git)')/pull/${id_pr:?}"
date=$(git log -1|git log --pretty=format:'%ci' -1)
line="${pr_url:?}\t$(git log --pretty=format:'%h' -1)\t${date}\t${item}\t$(get_pr_description)"
if [[ -f $filename ]]; then
  # break i-nodes
  cp "$filename" "${filename}.bak"
  rm "$filename"
  mv "${filename}.bak" "$filename"
else
  >$filename
fi
grep "$(echo -e $line)" $filename || echo -e $line>>$filename
exit 0
