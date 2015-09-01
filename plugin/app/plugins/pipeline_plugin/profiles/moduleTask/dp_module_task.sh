#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
moduleTask=$1
shift
### HELP section
dp_help_message="This command executes $moduleTask.sh script store in the home project. 

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

function execute(){
    if [ -f "./${moduleTask}.sh" ]; then
         if [ -x "./${moduleTask}.sh" ]; then
           >.${moduleTask}.sh
            ./${moduleTask}.sh
            errorCode=$?
            rm -Rf .${moduleTask}.sh
            return $errorCode
         else
            _log "The script [$moduleTask] has been delivered to the repo without execution permissions"
            return 1
         fi
      else
         if [ -f "$DP_HOME/dp_${moduleTask}.sh" ]; then
            $DP_HOME/dp_${moduleTask}.sh
            return $?
         else
            _log "[$moduleTask] phase is not defined in the deployment pipeline." 
            return 1
         fi
      fi
}

isExecutedInDevelenv
if [ "$isDevelenv" == "false" ]; then
   execute
fi
