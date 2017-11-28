#!/bin/bash

[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/phases/build/projectType.sh build
source $DP_HOME/tools/versions/dp_version.sh

function init(){
   _log "[INFO] Calculating metrics"
   JOB_HOME=`readlink -f ./`
   OUTPUT_DIR="$JOB_HOME/target/"
   mkdir -p $OUTPUT_DIR
}

function isPipelineJob(){
   [[ -z $PIPELINE_ID ]] && return 1 || return 0
}

function getProjectKey(){
   isPipelineJob
   [[ $?  == 1 ]] && \
      echo "${PROJECT_GROUPID}.${PROJECT_NAME}.${JOB_NAME}" && \
      return ;
   echo "${PIPELINE_ID}.${JOB_NAME}"
}

function getUrlCi(){
   echo $JENKINS_URL/job/$JOB_NAME
}

#Execute out of jenkins
function externalConfiguration(){
   if [[ -z "$JOB_NAME" ]]; then
      pushd . >/dev/null
      while [ ! -d "workspace" ] && [ ! "$PWD" = "/" ]; do cd ..; done
      WORKSPACE=$PWD/workspace
      JOB_NAME=$(basename $(dirname $WORKSPACE))
      PIPELINE_ID=$(echo $JOB_NAME|cut -d'-' -f1)
      JENKINS_URL=http://$(hostname)/jenkins
      popd >/dev/null
   fi

}

function execute_with_sonar_project_file(){
   WORKSPACE=$PWD
   echo "sonar-scanner"
}

function execute_without_sonar_project_file(){
   init
   externalConfiguration
   local thisFile=$DP_HOME/profiles/metrics/dp_metrics_with_sonarRunner.sh
   local default_version_module="0.0"
   local errorCode
   local lineSeparator=$(grep -n "############################### SONAR_RUNNER ###############################" $thisFile|grep -v "grep"|cut -d ':' -f1)
   local scmStats="true"
   local scmType="none"
   local scm
   local sonarFileconf=${OUTPUT_DIR}/sonar-project.properties
   local sonarProperty
   local versionModule
   sed 1,${lineSeparator}d $thisFile > ${sonarFileconf}
   sed -i s:"SONAR_KEY":"$JOB_NAME":g ${sonarFileconf}
   versionModule=$(getVersionModule)
   errorCode=$?
   [[ "$errorCode" != 0 ]] && versionModule=$default_version_module
   [[ "$errorCode" != 0 ]] && isPipelineJob && return $errorCode
   echo "sonar.projectVersion=$versionModule" >>${sonarFileconf}
   echo "sonar.projectKey=$(getProjectKey)" >>${sonarFileconf}
   scmType=$(getSCM)
   scm=$(scmUrl_${scmType})
   [[ "$scmType" == "mercurial" ]] && scmStats="false"
   if [ "$scmType" != "none"  -a  scmStats="true" ]; then
      echo "sonar.scm-stats.enabled=${scmStats}"  >> ${sonarFileconf}
      echo "sonar.scm.url=$scm">> ${sonarFileconf}
      echo "sonar.scm.enabled=true" >> ${sonarFileconf}
   else
      echo "sonar.scm-stats.enabled=false" >> ${sonarFileconf}
      echo "sonar.scm.enabled=false" >> ${sonarFileconf}
   fi
   echo "sonar.build-stability.url=Hudson:"$(getUrlCi) >> ${sonarFileconf}
   typeBuildProject=$(get_phase_TypeProject)
   typeMetrics_${typeBuildProject} ${sonarFileconf}
   echo "sonar-scanner -Dsonar.projectBaseDir=$WORKSPACE \
   -Dproject.settings=${sonarFileconf}"
}
function execute(){
   local command=""
   sonarFileconf="sonar-project.properties"
   if [ -f "$sonarFileconf" ]; then
      command=$(execute_with_sonar_project_file)
   else
      command=$(execute_without_sonar_project_file)
   fi
   ${command}
   errorCode=$?
   if [ "$errorCode" != "0" ]; then
      _log "[ERROR] Error in sonar Runner Execution"
      return $errorCode
   fi
   local url_sonar_resource="$(grep ^sonar.projectKey= ${sonarFileconf}|cut -d'=' -f2)"
   mkdir -p $(dirname "$WORKSPACE/../metrics/sonar")
   echo $url_sonar_resource py>>$WORKSPACE/../metrics/sonar
   _log "[INFO] Metrics calculated"
   return $errorCode
}

return $?
############################### SONAR_RUNNER ###############################
# Automatically generated with deployment pipeline plugin
sonar.projectName=SONAR_KEY
sonar.sources=./
sonar.dynamicAnalysis=reuseReports
sonar.exclusions=tests/**,**/tests/**

