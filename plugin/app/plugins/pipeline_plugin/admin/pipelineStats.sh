#!/bin/bash
. /home/develenv/bin/setEnv.sh
set +e
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function pipelineError(){
   errorMessage="$1"
   _log "[ERROR] $errorMessage"
}

function pipelineWarning(){
   warningMessage="$1"
   _log "[WARNING] $warningMessage"
}

function exitError(){
   pipelineError "$1"
   if [ $2 != "" ]; then
      exit $2
   else
      exit 1
   fi
}

function help(){
   _message "Uso: $0 <reportFile>"
}

function init(){
   if [ "$#" != "1" ]; then
      help
      exit 1;
   fi
}

function execute(){
   local reportFile=$1
   local dirLastStates="$PROJECT_HOME/app/sites/\
pipelinesReports/lastStates"
   mkdir -p $dirLastStates
   cp $reportFile $dirLastStates/`basename ${reportFile%-[0-9]*}`
}

init $*
execute $*

