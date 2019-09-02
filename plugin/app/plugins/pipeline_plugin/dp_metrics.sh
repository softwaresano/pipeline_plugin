#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
###HELP section
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'
dp_help_phase='metrics'


source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

source $DP_HOME/phases/build/dp_task.sh "metrics"
errorCode=$?
if [ "$errorCode" != 0 ]; then
   _log "[ERROR] In metric phase"
   exit $errorCode
fi

$DP_HOME/profiles/metrics/dp_build_metricsOk.sh
errorCode=$?
if [ "$errorCode" != 0 ]; then
   _log "[ERROR] The metrics are worst than last execution"
    exit $errorCode
fi
