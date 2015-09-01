#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[pythonTemplate] package type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/tools/versions/dp_version.sh
source $DP_HOME/profiles/package/pythonTemplate/createRpm.sh
CACHE_REQUIREMENTS=".requirements.txt"
function getConfiguration(){
   local rootDir
   while [[ ! -f ${rootDir}neore/config/project.cfg ]]; do 
      rootDir=${rootDir}../; 
      if [[ "$(readlink -f ${rootDir})" == "/" ]]; then
         _log "[ERROR] No project.cfg found"
         exit 1
      fi
   done
   local filesConf="${rootDir}neore/config/project.cfg \
                    ${rootDir}neore/config/project.local.cfg \
                    ../neore/config/component.cfg \
                    ../neore/component.local.cfg"
   for fileConf in $filesConf; do
      if [ -f "$fileConf" ]; then
         source $fileConf
      fi
   done;
   if [ -z "$ORGANIZATION" ]; then
      _log "[ERROR] ORGANIZATION variable is empty"
      exit 1
   fi
   if [ -z "$PROJECT_NAME" ]; then
      _log "[ERROR] PROJECT_NAME variable is empty"
      exit 1
   fi
   if [ -z "$COMPONENT_NAME" ]; then
      _log "[ERROR] COMPONENT_NAME variable is empty"
      exit 1
   fi   
}

function areTheSameDependencies(){
  [[ ! -f $CACHE_REQUIREMENTS ]] && return 1
  local oldRequirements=$(cat $CACHE_REQUIREMENTS)
  local newRequirements=$(cat requirements.txt)
  [[ "$oldRequirements" == "$newRequirements" ]] && \
    [[ -f "rpm_requires.txt" ]] && return 0
  return 1
}

function generateRpmDependencies(){
  areTheSameDependencies && return 0
  $DP_HOME/profiles/package/pythonTemplate/package.sh
  RET_VAL=$?
  if [[ $RET_VAL -ne 0 ]]; then
     rm -Rf $CACHE_REQUIREMENTS rpm_requires
     return $RET_VAL
  fi
  cp requirements.txt $CACHE_REQUIREMENTS
  return $RET_VAL
}

function createLocalComponent(){
   local componentName=$(echo $COMPONENT_NAME|sed s:"${PROJECT_NAME}-":"":g)
   local requires="$RPM_DEPENDENCIES $(cat rpm_requires.txt)"
   createRpm \
        templates/python-component.spec.template \
        $PWD \
        /opt/$ORGANIZATION/$PROJECT_NAME/$componentName \
        $componentName \
        $(getVersionModule) \
        $(getReleaseModule) \
        "$PROJECT_NAME" \
        "$ORGANIZATION" \
        "$PROJECT_NAME" \
        "${requires}"
   RET_VAL=$?
   if [ "$RET_VAL" != "0" ]; then
      return $RET_VAL
   fi
}

function execute(){
   getConfiguration && \
   generateRpmDependencies && \
   createLocalComponent
   if [ "$RET_VAL" != "0" ]; then
      return $RET_VAL
   fi

}

execute