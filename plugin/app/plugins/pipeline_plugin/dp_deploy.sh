#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'
dp_help_phase='deploy'

source $DP_HOME/dp_help.sh $*

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/phases/deploy/projectType.sh

getDeployTypeProject $*
errorCode=$?
if [ "$errorCode" != 0 ]; then
   exit $errorCode
fi

sudo yum clean all
$DP_HOME/profiles/deploy/${typeDeployProject}/dp_deploy.sh $*
#install develop \
#   sprayer1 1 sprayer2 1 sprayer3 1 
