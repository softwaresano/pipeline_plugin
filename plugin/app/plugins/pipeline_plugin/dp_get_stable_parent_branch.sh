#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)

###HELP section
dp_help_message='Returns parent stable branch

Usage: dp_get_stable_parent_branch.sh'

source $DP_HOME/dp_help.sh $*

###END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/versions/dp_version.sh

get_stable_parent_branch
