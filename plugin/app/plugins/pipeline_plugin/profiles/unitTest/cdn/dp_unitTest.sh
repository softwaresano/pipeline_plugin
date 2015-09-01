#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[cdn] unittest type
"
source $DP_HOME/dp_help.sh $*
### END HELP section
source $DP_HOME/dp_setEnv.sh
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
   
function execute(){
   [ "$(which make 2>/dev/null)" == "" ] && _log "[ERROR] make isn´t in the PATH" && return 1
   make tests
}

if [ "$isDevelenv" == "false" ]; then
   execute
fi
errorCode=$?
return $?
