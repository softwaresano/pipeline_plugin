#!/bin/bash
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
function get_phase_Type(){
   typePackageProject=""
   currentFile=$DP_HOME/phases/$phase/projectType.sh
   for packageType in `cat $currentFile|grep "^function is_$phase_Type.*()"|awk '{ print $2 }'|sed s:"(.*":"":g`;do
      #If it is a customType only you can package one package type
      if [ "$customType" != "true" ]; then
         $packageType
      fi
   done;
   if [ "$typePackageProject" != "" ]; then
      return 0
   fi
   return 1
}

function get_phase_TypeProject(){
   if [ "$phase" == "" ]; then
      return 0
   fi
   get_phase_Type
   errorCode=$?
   if [ "$errorCode" != "0" ]; then
      _log "[ERROR] The configuration for the $phase is not defined"
      return $errorCode
   else
      if [ "$typePackageProject" == "" ]; then
         typePackageProject="withoutType"
      fi
      echo $typePackageProject
      return $errorCode
   fi
}
