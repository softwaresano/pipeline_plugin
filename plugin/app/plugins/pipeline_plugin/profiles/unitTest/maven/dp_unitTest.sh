#!/bin/bash
### HELP section
dp_help_message="This command has not any help
[maven] unittest type
"
source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function execute(){
   local mavenArguments=""
   [ "$(which mvn 2>/dev/null)" == "" ] && _log "[ERROR] maven isn´t in the PATH" && return 1

   [[ "$(grep "cobertura-maven-plugin" pom.xml)" != "" ]] && \
      mavenArguments="$mavenArguments cobertura:cobertura -Dcobertura.report.format=xml"
   _log "[INFO] mvn install $mavenArguments"
   mvn install $mavenArguments
}