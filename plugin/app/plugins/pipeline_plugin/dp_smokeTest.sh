#!/bin/bash
[ -z $DP_HOME ] && export DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
### HELP section
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'

source $DP_HOME/dp_help.sh $*
### END HELP section


if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi 


function execute(){
    echo "[ERROR] SmokeTest phase is not implemented"
    return 1
}
execute