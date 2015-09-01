#!/bin/bash
### HELP section
dp_help_message="This command has not any help
[maven] docs type
"
source $DP_HOME/dp_help.sh $*
### END HELP section
function execute(){
   [ "$(which mvn 2>/dev/null)" == "" ] && _log "[ERROR] maven isn´t in the PATH" && return 1
   local mavenArguments=""
   sed 1,`expr $(cat pom.xml|grep -n "<distributionManagement>"|cut -d':' -f1) - 1`d pom.xml >.deleteme 2>/dev/null
   if [ "$?" == "0" ]; then
      sed -i `expr $(cat .deleteme|grep -n "</distributionManagement>"|cut -d':' -f1) + 1`,10000d .deleteme 2>/dev/null
      if [ "`cat .deleteme|grep \"</site>\"`" != "" ]; then
         mavenArguments="$mavenArguments site:site" 
         if [ "$isDevelenv" == "true" ]; then
            mavenArguments="$mavenArguments site:deploy" 
         fi         
      fi
   fi
   rm -Rf .deleteme
   if [ "$mavenArguments" != "" ]; then
      _log "[INFO] mvn $mavenArguments"
      mvn $mavenArguments
   fi
}