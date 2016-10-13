#!/bin/bash
item=$(git log -1|egrep  "Merge pull request #[0-9]+ from"|sed s:"    Merge pull request.*from":"":g|awk '{print $1}'|cut -d'/' -f2-)
[[ "$item" == "" ]] && exit 0
[ -z $DP_HOME ] && export DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
source $DP_HOME/profiles/publish/rpm/dp_publish.sh
version=$(dp_version.sh)
filename="$(dirname $(get_repo_dir))/release-notes-$version.txt"
repo=$(git config --get remote.origin.url)
date=$(git log -1|grep ^Date|cut -d ' ' -f4-)
line="${repo}\t$(git log --pretty=format:'%h' -1)\t${date}\t${item}"
if [[ -f $filename ]]; then
  # break i-nodes
  cp $filename ${filename}.bak
  rm $filename
  mv ${filename}.bak $filename
else
  >$filename
fi

[[ "$(grep \"'$line'\" $filename)" == '' ]] && echo -e $line>>$filename
exit 0