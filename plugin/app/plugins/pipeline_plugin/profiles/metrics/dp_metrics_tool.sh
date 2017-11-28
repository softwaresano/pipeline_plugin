#!/bin/bash
source $DP_HOME/config/dp.cfg

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function isSonarOk(){
[ "$(which sonar-scanner 2>/dev/null)" == "" ] && return 1
   local wget_test_result=$(curl -s -o /dev/null -w "%{http_code}" ${SONAR_URL}/)
   case $wget_test_result in
      200)
         return 0
      ;;
      403)
         return 403
      ;;
      *)
         return 1
      ;;
   esac
}

function getMetricsTool(){
   local tool="withoutMetricsConfig"
   if [ -f pom.xml ]; then
         tool="sonar"
   else
      if [ -f sonar-project.properties ]; then
         tool="sonarRunner"
      fi
   fi
   if [ "$tool" != "withoutMetricsConfig" ]; then
      isSonarOk
      if [ $? != 0 ]; then
         tool="withoutSonar"
      fi
   fi
   # If it's a develenv execution and metrics_runner is installed
   # then the metrics are calculated with metrics_runner"
   if [ "$(id -un)" == "develenv" -a \
        "$JOB_NAME" != "" -a \
        "$tool" != "withoutMetricsConfig" -a \
        "$(which metrics_calculator.sh 2>/dev/null)" != "" ]; then
      tool="metrics_calculator"
   fi
   echo $tool
}
