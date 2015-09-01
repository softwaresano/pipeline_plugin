#!/bin/bash
### HELP section
dp_help_message="This command has not any help
[maven] compile type
"
source $DP_HOME/dp_help.sh $*
### END HELP section
function execute(){
   [ "$(which mvn 2>/dev/null)" == "" ] && _log "[ERROR] maven isn´t in the PATH" && return 1
   mvn clean compile
}