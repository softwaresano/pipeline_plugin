#!/bin/bash
#Publish all artifacts stored in the tree directory. At the moment only rpms
[ -z $DP_HOME ] && export DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)
### HELP section
dp_help_phase="publish"
dp_help_message='This command has not any help

Usage: dp_publish.sh'

source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

$DP_HOME/tools/dp_default.sh publish $*
