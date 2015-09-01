#!/bin/bash

[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1

source $DP_HOME/dp_setEnv.sh
### HELP section
dp_help_message="This command has not any help
[STATIC WEB] type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/profiles/build/default/dp_build.sh

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function metricsOk(){
   _log "[WARNING] The metrics aren't configure"
}

function execute(){
   echo "[WARNING] Nothing to do"
   if [ "$errorCode" == "0" ]; then
      metricsOk
      errorCode="$?"
   fi
   return $errorCode
}

isExecutedInDevelenv
if [ "$isDevelenv" == "false" ]; then
   execute
   exit $?
fi

