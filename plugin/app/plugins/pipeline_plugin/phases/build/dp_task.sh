#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

buildTypeTasks="compile unitTest metrics docs"
typeTasks="build $buildTypeTasks"
function help(){
   _message "dp_task [$typeTasks]"
}

function init(){
   _log "[INFO] --------------------------"
   _log "[INFO]  INIT $1 $2 task"
   _log "[INFO] --------------------------"
}

function finalizeWithError(){
   _log "[ERROR] --------------------------"
   _log "[ERROR]  $1 $2 task failed"
   _log "[ERROR] --------------------------"
}

function testParameters(){
   [[ $# == 1 ]] && echo $typeTasks|grep $1 >/dev/null && return 0;
   if [ $# != 1 ]; then
      _log "[ERROR] Incorrect parameters"
   else
      _log "[ERROR] $1 isn't a task"
   fi
   help
   return 1
}

testParameters $*
[[ $? != 0 ]] && exit 1 
task=$1
source $DP_HOME/phases/build/projectType.sh build
typeBuildProject=$(get_phase_TypeProject)
errorCode=$?
if [ "$errorCode" != 0 ]; then
   exit $errorCode
fi
if [ ! -f "$DP_HOME/profiles/${task}/$typeBuildProject/dp_${task}.sh" ]; then
   if [ -f "$DP_HOME/profiles/${task}/default/dp_${task}.sh" ]; then
      typeBuildProject="default"
   else
      _log "[WARNING] Default [${task}] task doesn't exist for \
[${typeBuildProject}] project type. Is it correct?"
   fi
fi
if [ -f ${task}.sh -a ! -f .${task}.sh ]; then
   if [ -x ${task}.sh ]; then
      _log "[INFO] Executing custom ${task}[./${task}.sh]"
      init ${task} "custom"
      source ./${task}.sh
   else
      _log "[ERROR] [${task}.sh] hasn't execution permissions"
      finalizeWithError ${task} "custom"
      exit 1
   fi
else
   if [ -f "$DP_HOME/profiles/${task}/$typeBuildProject/dp_${task}.sh" ]; then
      _log "[INFO] Executing default ${task}[dp_${task}.sh] for $typeBuildProject"
      init ${task} "default"
      source $DP_HOME/profiles/${task}/${typeBuildProject}/dp_${task}.sh
      execute
      errorCode=$?
      if [ "$errorCode" != "0" ]; then
            finalizeWithError ${task} "default"
            exit $errorCode
      else
         _log "[INFO] Success default ${task}[dp_${task}.sh] execution for $typeBuildProject"
      fi
   else
         _log "[WARNING] There are not a script for the task [$task] with the project type [$typeBuildProject]"
   fi
fi
