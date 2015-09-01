#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command executes the default ant task described in the
ant buildfile (build.xml) stored in the home project
"
source $DP_HOME/dp_help.sh $*
### END HELP section
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function metricsOk(){
   _log "[WARNING] The metrics aren't configure"
}

function execute(){
   [ "$(which ant 2>/dev/null)" == "" ] && _log "[ERROR] ant isn´t in the PATH" && return 1
   ant
   errorCode="$?"
   if [ "$errorCode" == "0" ]; then
      metricsOk
      errorCode="$?"
   fi
   return $errorCode
}
isExecutedInDevelenv
if [ "$isDevelenv" == "false" ]; then
   execute
fi
