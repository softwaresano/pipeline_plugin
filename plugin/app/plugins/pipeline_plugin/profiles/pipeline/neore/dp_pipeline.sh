#!/bin/bash
[ -z $DP_HOME ] && export DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)

### HELP section
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'

source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi 


function execute(){
   local task
   for task in $pipelineTypeTasks; do
      local fileTask="neore/scripts/${task}.sh"
      local errorCode
      if [ -f "$fileTask" ]; then
         $fileTask
         errorCode=$?
         if [ "$errorCode" != "0" ]; then
            _log "[ERROR] $task phase failure"
            return $errorCode
         fi
         _log "[INFO] $task phase successfull"

      fi
   done;
}
pipelineTypeTasks="build package deploy test.installation test.acceptance"
execute