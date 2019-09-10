#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
dp_help_message='This command executes

Usage: dp_acceptanceTests.sh'
source $DP_HOME/dp_help.sh $*

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi 


function execute(){
    echo "[ERROR] AcceptanceTest phase is not implemented"
    return 1
}
execute