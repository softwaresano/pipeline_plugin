#!/bin/bash
### HELP section
dp_help_message="This command has not any help
[iso] publish type
"
source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/profiles/publish/default/dp_publish.sh

function get_repo_dir(){
   if [ "$ALL_RPMS_IN_RPM_HOME" == "" ]; then
      echo $(dirname $(default_repo_dir))
   else
      echo $ALL_RPMS_IN_RPM_HOME
   fi
}




#Extracts the name of an artifact.
function get_artifact_name(){
   local artifact_file=$1
   echo $(basename $artifact_file)|sed s:"-[0-9]\+\.*.*":"":g
}


# Publish artifact in the right repository
function publish_isos(){
   local artifact_files=$1
   publish_artifacts "$artifact_files"
}


function execute(){
   publish "*.iso"
}

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   main --debug $*
else
   main $*
fi