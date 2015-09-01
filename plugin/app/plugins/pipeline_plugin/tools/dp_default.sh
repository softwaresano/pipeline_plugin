#!/bin/bash
## This is default phase is invoked by dp_package and dp_publish 

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

phase=$1
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

source $DP_HOME/phases/$phase/projectType.sh $phase

type_phase_project=$(get_phase_TypeProject)
errorCode=$?
if [ "$errorCode" != 0 ]; then
   exit $errorCode
fi
if [[ "$type_phase_project" == "" ]]; then
   _log "[ERROR] This project is not in any state of deployment pipeline(build,package,...)"
   exit 1
fi


for aTypePhaseProject in $type_phase_project; do
   type_phase_executable=$DP_HOME/profiles/$phase/${aTypePhaseProject}/dp_${phase}.sh
   if [ ! -f "$type_phase_executable" ]; then
      _log "[ERROR] There aren't any procedure to $phase a [${aTypePhaseProject}]"
      exit 1
   fi
   _log "[INFO] Executing default $phase[$type_phase_executable]"
   #Remove the first parameter $(phase)
   shift
   $type_phase_executable $*
   errorCode=$?
   if [ "$errorCode" != "0" ]; then
      _log "[ERROR] Failure default $phase[$type_phase_executable] execution"
      exit $errorCode
   else
      _log "[INFO] Success default $phase[$type_phase_executable] execution"
   fi
done;