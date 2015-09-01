#!/bin/bash

[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE


source $DP_HOME/tools/versions/dp_version.sh

function init(){
   _log "[INFO] Calculating metrics"
   JOB_HOME=`readlink -f ./`
   OUTPUT_DIR="$JOB_HOME/target/"
   mkdir -p $OUTPUT_DIR
}


function execute(){
   [ "$(which mvn 2>/dev/null)" == "" ] && _log "[ERROR] maven isn´t in the PATH" && return 1
   local mavenArguments="-Dsonar.cpd.cross_project=true"
   init
   if [[ -f target/site/cobertura/coverage.xml ]]; then
      mavenArguments="$mavenArguments -Dsonar.dynamicAnalysis=reuseReports \
         -Dsonar.java.coveragePlugin=cobertura"
   fi
  _log "[INFO] mvn sonar:sonar $mavenArguments"
   mvn sonar:sonar $mavenArguments
   return $?
}