#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
source $DP_HOME/profiles/moduleTask/dp_module_task.sh build $*