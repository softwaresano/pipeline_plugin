#!/bin/bash
[ -z $DP_HOME ] && export DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $(which dp_package.sh)/..)
###HELP section
dp_help_message='It creates a package of the project

Usage: dp_package.sh'
dp_help_phase="package"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

$DP_HOME/tools/dp_default.sh package $*
