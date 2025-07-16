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

# Maybe the project doesn't need a build. Only package. 
# At the moment only supports rpm.
function is_build_TypeProjectWithoutBuild(){
    [[ "$(find . -type f -name "*.spec")" != "" ]] && \
    typePackageProject="projectWithoutBuild"
}

function is_build_TypeCustom(){
   local dpSetupFile=$(find . -name ".dpSetup"|head -1)
   if [ "$dpSetupFile" != "" ]; then 
      source $dpSetupFile
      typePackageProject="$DP_BUILD_TYPE"
   fi
}

function is_build_TypeStaticWeb(){
    if [ -d "$PWD/src/main/webapp" ]; then
       typePackageProject="staticWeb"
    fi
}

function is_build_TypeMaven(){
   if [ "`find . -maxdepth 1 -name \"pom.xml\"`" != "" ]; then
      typePackageProject="maven"
   fi
}

function is_build_TypeAnt(){
   if [ "`find . -maxdepth 1 -name \"build.xml\"`" != "" ]; then
      typePackageProject="ant"
   fi
}

function is_build_TypeMakefile(){
    if [ "`find . -maxdepth 1 -name \"Makefile\"`" != "" ]; then
        typePackageProject="makefile"
    fi
}


function is_build_TypePython(){
    if [ -f "$PWD/setup.py" ]; then
       typePackageProject="python"
       return;
    fi
    # It is a django project
    [[ -f "$PWD/setup.py" ]] && \
    [[ "$(find . -name "manage.py" -exec grep -l django {} \;)" != "" ]] && \
    typePackageProject="python"
}


function is_build_TypeBuildScript(){
   if [ "`find . -maxdepth 1 -name \"build.sh\"`" != "" ]; then
      typePackageProject="buildScript"
   fi
}
