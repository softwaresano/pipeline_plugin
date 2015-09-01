#!/bin/bash 
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[python] metrics type
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


function typeMetrics_python(){
   local sonarFileconf=$1
   echo sonar.language=py >> ${sonarFileconf}
   echo sonar.python.xunit.reportPath=target/surefire-reports/TEST-nosetests.xml >> ${sonarFileconf}
   echo sonar.python.coverage.reportPath=target/site/cobertura/coverage.xml >> ${sonarFileconf}
}
source $DP_HOME/profiles/metrics/dp_metrics_tool.sh
source $DP_HOME/profiles/metrics/dp_metrics_with_$(getMetricsTool).sh

isExecutedInDevelenv
if [ "$isDevelenv" == "false" ]; then
   execute
fi
errorCode=$?
