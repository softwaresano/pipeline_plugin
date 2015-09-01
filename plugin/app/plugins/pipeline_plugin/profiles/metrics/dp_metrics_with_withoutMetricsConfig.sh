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


function execute(){
  _log "[WARNING] This project has not a metrics configuration file(sonar-project.properties or pom.xml). The metrics will not be calculated"
}