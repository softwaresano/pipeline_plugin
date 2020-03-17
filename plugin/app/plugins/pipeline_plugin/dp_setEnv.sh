#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)
PIPELINE_ID=$(echo $JOB_NAME|cut -d'-' -f1)
LANG=C

function isExecutedInDevelenv(){
   if [ "$HUDSON_HOME" != "" ]; then
      if [ -f $DP_HOME/temp/$PIPELINE_ID ]; then
         isDevelenv="true"
      else
         isDevelenv="false"
      fi
   else
        isDevelenv="false"
   fi
   export isDevelenv
}

function setupEnv(){
   isExecutedInDevelenv
   if [ "$isDevelenv" == "true" ]; then
      PROJECT_HOME=/home/develenv
      SET_ENV_FILE=$PROJECT_HOME/bin/setEnv.sh
   else
      PROJECT_HOME=$DP_HOME
      SET_ENV_FILE=$DP_HOME/tools/env/setEnv.sh
   fi
   export DP_HOME
   export PROJECT_HOME
   export PROJECT_USER=develenv
   export PROJECT_NAME=develenv
   export PROJECT_GROUPID=develenv
   export SET_ENV_FILE
   export PATH=$DP_HOME:$PATH
   export CUSTOM_SCRIPTS_DIR=../neore/scripts
   export TEST_UNIT_SCRIPT_FILE=test.unit.sh
   export DEVELENV_HOME=/home/develenv
}

setupEnv