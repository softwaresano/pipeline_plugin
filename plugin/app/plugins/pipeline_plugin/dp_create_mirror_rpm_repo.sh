#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
dp_help_message='Create a mirror of a rpm repo

Usage: dp_create_mirror_rpm_repo.sh <id_repo> <url_repo> <base_url>
Example:
   dp_create_mirror_rpm_repo.sh  nodejs-stable "https://rpm.nodesource.com/pub/el/6/\\\$basearch/" /home/vagrant/workspace/temp/nodejsrepo
EOF '

$DP_HOME/tools/mirror_rpm_repo/create_mirror.sh $*

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
