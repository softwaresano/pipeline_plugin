#!/bin/bash
[ -z $DP_HOME ] && export DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $(which dp_package.sh)/..)
###HELP section
dp_help_message='Returns repo_home path

Usage: dp_artifacts_repo_home.sh'
dp_help_phase="package"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/config/dp.cfg
source $DP_HOME/profiles/publish/default/dp_publish.sh
#echo $REPO_RPM_HOME/$(getVersionModule)
dirname $(default_repo_dir $1)
