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

function is_package_TypeCustom(){
   local dpSetupFile=$(find . -maxdepth 1 -name ".dpSetup"|head -1)
   if [ "$dpSetupFile" != "" ]; then 
      source $dpSetupFile
      typePackageProject="$DP_PACKAGE_TYPE ${typePackageProject}"
      customType="true"
   fi
}

function is_package_TypeRedhat(){
   # For security only 6 levels
   #  Máximum submodule/src/main/rpm/SPECS/
   if [ "$(find . -maxdepth 7 -name "*.spec"  -not -path "./target/*" -not -path "./external/*" -not -path "./.git/*" -not -path "./.scannerwork/*")" != "" ]; then
      typePackageProject="redhat ${typePackageProject}"
   fi
}

function is_package_TypeDebian(){
   if [ "`find . -maxdepth 1 -name \"*.deb\"`" != "" ]; then
      typePackageProject="debian ${typePackageProject}"
   fi
}

function is_package_TypeMakefile(){
    if [ "`find . -maxdepth 1 -name \"Makefile\"`" != "" ]; then
       if [ "$(grep \"^rpm\:\" Makefile)" != "" ]; then
          typePackageProject="makefile ${typePackageProject}"
       fi
    fi
}

function is_package_TypePythonPackageRpm(){
   local specFiles=$(find . -name "*.spec")
   [ -z "$specFiles" ] && [ -f "setup.py" ] && \
      typePackageProject="pythonTemplate ${typePackageProject}"
}

function is_package_TypePackageScript(){
   if [ -f package.sh ]; then
      typePackageProject="packageScript"
   fi
}
