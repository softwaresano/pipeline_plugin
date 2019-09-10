#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
dp_help_message='This command executes the build phase

Usage: dp_build.sh'
dp_help_phase='build'

source $DP_HOME/dp_help.sh $*

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi


source $DP_HOME/phases/build/dp_task.sh "build"
errorCode=$?
if [ "$errorCode" != 0 ]; then
   exit $errorCode
fi
$DP_HOME/profiles/metrics/dp_build_metricsOk.sh
exit $?
