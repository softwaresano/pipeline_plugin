#!/bin/bash
source $(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)/dp_setEnv.sh
source $SET_ENV_FILE

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function getDeployTypeProject(){
   typeDeployProject="vagrant"
   if [ $# -gt 0 -a "$1" != "local" ]; then
      typeDeployProject="aws"
   fi
}
