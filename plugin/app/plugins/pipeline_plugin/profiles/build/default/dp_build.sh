#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command executes the default task for the build phase. This
task are compile unitTest metrics docs
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
   local task
   for task in $buildTypeTasks; do
      local fileTask="$DP_HOME/profiles/${task}/$typeBuildProject/dp_${task}.sh"
      local errorCode
      if [ -f "$fileTask" ]; then
         _log "[INFO] Executing custom ${task}"
         source $fileTask
         execute
         errorCode=$?
         if [ "$errorCode" != "0" ]; then
            _log "[INFO] Failure custom ${task} execution. Review ${fileTask}"
            return $errorCode
         else
            _log "[INFO] Success custom ${task} execution"
         fi
      fi
   done;
}
