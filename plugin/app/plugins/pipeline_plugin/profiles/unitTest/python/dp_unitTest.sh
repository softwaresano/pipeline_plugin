#!/bin/bash

[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[python] unittest type
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

function init(){
   executionTests="$1"
   thisFile=$0
   pythonDirConf=$PROJECT_PLUGINS/python_plugin/conf/
   JOB_HOME=`readlink -f ./`
   OUTPUT_DIR="$JOB_HOME/target/"
   SITE_JOB=$OUTPUT_DIR/site
   TEST_REPORTS=$OUTPUT_DIR/surefire-reports/TEST-nosetests.xml
   COVERAGE_REPORT=$OUTPUT_DIR/site/cobertura/coverage.xml
   rm -Rf $SITE_JOB
   mkdir -p $SITE_JOB
   mkdir -p $(dirname $TEST_REPORTS)
   mkdir -p $(dirname $COVERAGE_REPORT)
}


function isExecutedInDevelenv(){
   if [ "`id -nu`" == "develenv" ]; then
      isDevelenv="true"
   else
      isDevelenv="false"
   fi
}

function execute(){
   local errorCode=$?
   init
   cd $JOB_HOME
   if [ "$executionTests" == "" ]; then
      local unitTestScript="$CUSTOM_SCRIPTS_DIR/$TEST_UNIT_SCRIPT_FILE"
      if [ ! -f "$unitTestScript" ]; then
         unitTestScript=$DP_HOME/profiles/python/building/$TEST_UNIT_SCRIPT_FILE
      fi
      $unitTestScript
      #nosetests --cover-erase --with-cov --cov-report=xml \
      #   --cov-config=$pythonDirConf/coverage.rc \
      #  --with-xunit --xunit-file=$TEST_REPORTS -sv
   else
       $executionTests
   fi
   errorCode=$?
   [[ "$errorCode" != 0 ]] && _log "[ERROR] Unable execute unit Test" \
         && return $errorCode
   unit_test_failure=`cat $TEST_REPORTS |grep "failures"|cut -d'=' -f7|cut -d'"' -f2`
   unit_test_errors=`cat $TEST_REPORTS |grep "failures"|cut -d'=' -f6|cut -d'"' -f2`
   if [ "$unit_test_failure" != "0" ]; then
      _log "[ERROR] $unit_test_failure Fallos en los tests Unitarios"
      return 1
   fi
   if [ "$unit_test_errors" != "0" ]; then
      _log "[ERROR] $unit_test_errors Errores en los tests Unitarios"
     return 1
   fi
   [[ -f $COVERAGE_REPORT ]] && \
      sed -i s:"<packages>":" <sources><source>--source</source><source>$PWD</source></sources><packages>":g \
        $COVERAGE_REPORT || _log "[WARNING] Doesn't exist coverage report"
   _log "[INFO] All Tests Ok"
   return 0
}

isExecutedInDevelenv
if [ "$isDevelenv" == "false" ]; then
   execute
fi

