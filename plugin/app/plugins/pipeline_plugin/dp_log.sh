#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)
###HELP section
dp_help_message='Prints a log message with diferents colours:

INFO    --> blue
WARNING --> yellow
ERROR   --> red

Usage: dp_log.sh
'

source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

_log "$*"
