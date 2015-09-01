#!/bin/bash
phase=$1
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/phases/default/projectType.sh


if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function is_pipeline_TypeNeore(){
  if [ -d "neore/scripts/" ]; then
      typePackageProject="neore"
   fi
}

function is_pipeline_TypeJenkins(){
  if [ "$JOB_NAME" != "" ]; then
      typePackageProject="jenkins"
   fi
}

