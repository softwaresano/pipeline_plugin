#!/bin/bash
### HELP section
source $DP_HOME/config/dp.cfg
dp_help_message="Publish Python component in $CI_SERVER/devpi/develenv/dev/+simple/
"
source $DP_HOME/dp_help.sh $*
### END HELP section

source $DP_HOME/profiles/publish/default/dp_publish.sh

# Publish python component in the correct repository
function publish_pys(){
   local python_components=$1
   if [ "$(which devpi-upload.sh 2>/dev/null)" == "" ]; then
      _log "[WARNING] devpi client is not installed."
      return 0
   fi
   local error_code=0
   for python_component in $python_components; do
      pushd . >/dev/null
      if devpi-upload.sh; then
         _log '[INFO] Python component successfully deployed in devpi server'
      else
         _log '[ERROR] Python component has not been deployed'
         error_code=1
      fi
      popd >/dev/null
   done;
   return $error_code
}

function execute(){
   publish "setup.py"
}

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   main --debug $*
else
   main $*
fi
