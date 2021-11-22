#!/bin/bash
phase=$1
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/phases/default/projectType.sh


if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function isArtifactType(){
   if [ "`find . -name \"*.$1\"`" != "" ]; then
      typePackageProject="$1 ${typePackageProject}"
   fi
   }
function is_publish_TypeRpm(){
   isArtifactType rpm
}

function is_publish_TypePython(){
   if [ "`find . -name \"setup.py\" -not -path \"./external/*\"`" != "" ]; then
      typePackageProject="python ${typePackageProject}"
   fi
}

function is_publish_TypeIso(){
   isArtifactType iso
}

function is_publish_TypeThirdPartyRpmDependencies(){
   if [ -f "thirdparty-rpms.txt" ]; then
      if [ "$typePackageProject" != "" ]; then
         if [[ "$typePackageProject" != *rpm* ]]; then
            typePackageProject="rpm ${typePackageProject}"
         fi
      fi
   fi

}
