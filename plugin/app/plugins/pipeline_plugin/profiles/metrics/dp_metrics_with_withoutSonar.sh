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
  _log "[WARNING] Sonar isn´t present in this hosts. Metrics will not be calculated"
}