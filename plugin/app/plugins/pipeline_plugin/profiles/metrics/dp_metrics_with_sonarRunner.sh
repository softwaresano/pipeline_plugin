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
      echo "sonar.links.scm=$scm">> ${sonarFileconf}
      echo "sonar.scm.enabled=true" >> ${sonarFileconf}
   else
      echo "sonar.scm-stats.enabled=false" >> ${sonarFileconf}
      echo "sonar.scm.enabled=false" >> ${sonarFileconf}
   fi
   echo "sonar.links.ci="$(getUrlCi) >> ${sonarFileconf}
   typeBuildProject=$(get_phase_TypeProject)
   typeMetrics_${typeBuildProject} ${sonarFileconf}
   echo "sonar-scanner -Dsonar.projectBaseDir=$WORKSPACE \
   -Dproject.settings=${sonarFileconf}"
}
function get_sonar_project_key(){
  echo "$(git config --get remote.origin.url|grep -Po '(?<=\:).*(?=\.git$)'|sed s#/#:#g):$(dp_version.sh)"
}

function get_sonar_pr_parameters(){
  if [[ "${CHANGE_ID}" != '' ]]; then
    echo "-Dsonar.report.export.path=report.json -Dsonar.analysis.mode=issues -Dsonar.github.pullRequest=${CHANGE_ID}"
  fi
}
 
function get_sonar_implicit_options(){
  local sonar_parameters=""
  if [[ "${JOB_URL}" != '' ]]; then
    sonar_parameters="-Dsonar.links.ci=${JOB_URL} ${sonar_parameters}"
  fi
  grep '^sonar.links.scm=' $sonarFileconf >/dev/null || \
    sonar_parameters="-Dsonar.links.scm=$(git config --get remote.origin.url) ${sonar_parameters}"
  grep '^sonar.projectVersion=' $sonarFileconf >/dev/null || \
    sonar_parameters="-Dsonar.projectVersion=$(dp_version.sh)-$(dp_release.sh) ${sonar_parameters}"
  grep '^sonar.github.repository=' $sonarFileconf >/dev/null || \
    sonar_parameters="-Dsonar.github.repository=$(git config --get remote.origin.url|grep -Po '(?<=\:).*(?=\.git$)') ${sonar_parameters}"
  local sonar_cnes_report_property=''
  [[ -s "${CNES_REPORT}" ]] && sonar_cnes_report_property=" -Dsonar.icode.reports.path=${CNES_REPORT}"
  echo "${sonar_parameters}${sonar_cnes_report_property}"
}

function run_sonar_scanner(){
  local sonar_command=$1
  local parse_errors
  local ret_val
  _log "[INFO] Sonar command: ${sonar_command}"
  mkdir -p target/logs 
  ${sonar_command} 2>&1|tee target/logs/sonar.log && ret_val="${PIPESTATUS[0]}"
  parse_errors=$(egrep -A5 "^(ERROR: Unable to parse file|INFO: Compilation failed|ERROR: Failure during analysis)" target/logs/sonar.log)
  if [[ "${parse_errors}" != '' ]]; then
    _log "[ERROR] Error. Sonar can not parse file: ${parse_errors}"
    return 1
  fi
  [[ $ret_val == 0 ]] && return 0
  _log "[ERROR] Error in sonar Runner Execution"
  return 1
}

function run_shell_script_analysis(){
  local sh_files=$(find * -name "*.sh")
  [[ "${sh_files}" == '' ]] && return 0
  local icode_executable=/opt/ss/develenv/platform/i-CodeCNES/icode
  ! [[ -x "${icode_executable}" ]] && return 0
  mkdir -p "$(dirname "${CNES_REPORT}")"
  rm -f "${CNES_REPORT}"
  
  _log "[INFO] Running shell script_analysis:"
  _log "[INFO] ${icode_executable} $sh_files -o ${CNES_REPORT}"
  ${icode_executable} $sh_files -o "${CNES_REPORT}"
}
function execute(){
   local command=""
   CNES_REPORT=target/reports/CNES.xml
   #run_shell_script_analysis
   sonarFileconf="sonar-project.properties"
   if [ -f "$sonarFileconf" ]; then
      command=$(execute_with_sonar_project_file)
   else
      command=$(execute_without_sonar_project_file)
   fi
   local sonar_implicit_options=$(get_sonar_implicit_options)
   local sonar_project_key=$(get_sonar_project_key)
   local sonar_command=''
   local sonar_project_name=''
   local change_id_prefix=''
   if [[ "${CHANGE_ID}" != '' ]]; then
     change_id_prefix="${CHANGE_ID}:"
     sonar_project_name="${change_id_prefix}${sonar_project_key}"
     sonar_command="${command} -Dsonar.projectKey=${sonar_project_key} -Dsonar.projectName=${sonar_project_name} ${sonar_implicit_options} $(get_sonar_pr_parameters)"
     run_sonar_scanner "${sonar_command}" || return 1
   fi
   grep '^sonar.projectName=' $sonarFileconf >/dev/null || sonar_implicit_options="-Dsonar.projectName=${change_id_prefix}${sonar_project_key} ${sonar_implicit_options}"
   sonar_command="${command} -Dsonar.projectKey=${change_id_prefix}${sonar_project_key} ${sonar_implicit_options}"
   run_sonar_scanner "${sonar_command}" || return 1
   _log "[INFO] Metrics calculated"
}

return $?
############################### SONAR_RUNNER ###############################
# Automatically generated with deployment pipeline plugin
sonar.projectName=SONAR_KEY
sonar.sources=./
sonar.dynamicAnalysis=reuseReports
sonar.exclusions=tests/**,**/tests/**

