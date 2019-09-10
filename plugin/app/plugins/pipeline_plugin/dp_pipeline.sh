#!/bin/bash
[ -z $DP_HOME ] && export DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $(which dp_package.sh)/..)
### HELP section
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'
dp_help_phase="pipeline"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

$DP_HOME/tools/dp_default.sh pipeline $*
error_code=$?
isExecutedInDevelenv
rm -Rf $DP_HOME/temp/$PIPELINE_ID
if [ "$isDevelenv" == "true" ]; then
   exit $error_code
fi