#!/bin/bash

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
### HELP section
#This script contain commons functions for the all artifacts types.
dp_help_message=" "
source $DP_HOME/dp_help.sh $*
### END HELP section
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

source $DP_HOME/tools/versions/dp_version.sh
source $DP_HOME/config/dp.cfg

DP_PUBLISH_LOCK_FILE=".dp_publish_lock_file"
DP_PUBLISH_MAX_TIME_BLOCKED=180 # in seconds
DP_BLOCK_PUBLISH_DIRECTORY=$(dirname $REPO_RPM_HOME)/.lock

function get_block_directory(){
    echo $DP_BLOCK_PUBLISH_DIRECTORY/$(dirname $(default_repo_dir))
}

function is_blocked(){
    local block_directory=$(get_block_directory)
    if [ -f $block_directory/$DP_PUBLISH_LOCK_FILE ]; then
       echo "true"
    else
       echo "false"
    fi
}


# When starts the publication of an artifact, block repo
function block_publish(){
    local block_directory=$(get_block_directory)
    _log "[INFO] Avoid new publications in $block_directory directory"
    mkdir -p $block_directory
    echo "" > $block_directory/$DP_PUBLISH_LOCK_FILE
}

# When ends the publication of an artifact, unblock repo
function unblock_publish(){
    local block_directory=$(get_block_directory)
    _log "[INFO] Enable new publications in $block_directory directory"
    rm -f $block_directory/$DP_PUBLISH_LOCK_FILE
}

function default_repo_dir(){
    local is_user_story=$1
    branch=$(get_scm_branch)
    local repo_home_dir=$(dirname ${REPO_RPM_HOME})/releases/
    local relative_dir=$(getVersionModule)/$(get_os_release)
    local environment="developers"
    case $branch in
        develop|master|release/*) environment="rc";;
    esac
    local dir_repo=""
    [[ "$is_user_story" == "true" ]] && [[ "$environment" == "rc" ]] && return
    if [ "$environment" == "rc" -o "$is_user_story" != "true" ]; then
      dir_repo=${repo_home_dir}/${relative_dir}/${environment}/initiative
    else
      dir_repo=${repo_home_dir}/${relative_dir}/us/$branch/initiative
    fi
    echo $dir_repo
}

function is_new_artifact(){
   [ -f "$(get_repo_dir $fullName)/$fullName" ] && echo "true" || echo "false"
}

function publish_in_user_story(){
  local artifact_file=$1
  local rpm_file_name=$(basename $artifact_file)
  local dir_repo=$(default_repo_dir "true")
  if [[ "$dir_repo" != "" ]]; then
    local user_story_id=$(basename $(dirname $dir_repo)|cut -d'/' -f2|cut -d'_' -f1)
    local user_story_repo=$(dirname $(dirname $(dirname $dir_repo)))/$user_story_id/initiative
    mkdir -p $dir_repo $user_story_repo
    cp $artifact_file $user_story_repo
    createrepo $user_story_repo
    rm -f $dir_repo/$rpm_file_name
    ln $user_story_repo/$rpm_file_name $dir_repo/$rpm_file_name
    createrepo $dir_repo
  fi
}
function publish_artifact(){
   local artifact_file=$1
   local target_repo=$2
   local artifact_name=$(get_artifact_name "$artifact_file")
   local metadata_dir="$(dirname $target_repo)/.$(basename $target_repo)"
   local metadata_file="$metadata_dir/$artifact_name"
   mkdir -p $metadata_dir
   local branch_type=$(dp_branch_type.sh)
   if [ -f $metadata_file ]; then
     if [[ "${branch_type}" != 'release' ]]; then
      if [ '$(echo $N_RPMS_FOR_COMPONENT|egrep "^[0-9]+$")' != '' ]; then
         # Only the last (n_entry) 
         n_entry=$N_RPMS_FOR_COMPONENT
         k=$(expr $(cat $metadata_file|wc -l) - $n_entry + 1)
         if [ $k -gt 0 ]; then
            for file in $(head -${k} $metadata_file); do
                rm -f $target_repo/$file
            done
            tail -$n_entry $metadata_file >$metadata_file.tmp
            mv $metadata_file.tmp $metadata_file
         fi
      fi
     fi
   fi
   echo $(basename $artifact_file) >>$metadata_file
   cp "$artifact_file" "${target_repo}"
   if [[ "$ALL_RPMS_IN_RPM_HOME" == "" ]]; then
    publish_in_user_story "$artifact_file"
   fi
}
# Publish artifact in the right repository
function publish_artifacts(){
   local artifact_files=$1
   local oldIFS=$IFS
   local archs_file=${artifact_files}.arch
   rm -f $archs_file
   IFS=$'\n'
   local target_repo=""
   for artifact_file in $(cat $artifact_files 2>/dev/null)
       do
        target_repo="$(get_repo_dir $artifact_file)"
        mkdir -p $target_repo
        if [ "$(dirname $artifact_file)" != "$target_repo" ]; then
           publish_artifact "$artifact_file" "${target_repo}"
        fi
        _log "[INFO] ${target_repo}/$(basename $artifact_file) published successfully"
        echo $artifact_file|cut -d'.' -f$(expr $(echo $artifact_file|cut -d'.' -f1- --output-delimiter=$'\n'|wc -l) - 1) >>$archs_file
   done
   IFS=$oldIFS
}

# Publish artifact in a concrete repository. This repo depends on artifact_type
# (iso or rpm) and the tag version in scm
function publish(){
   # Check it is generated from a scm repo
   getVersionModule
   $(getVersionModule) && [[ $? != 0 ]] && echo "[ERROR] I can not publish an artifact without version" && exit 1
   local artifact_regr_expr=$1
   # Can i publish new artifact?
   local i=1
   while [[ "$(is_blocked)" == "true" ]]; do
        [[ $i -gt $DP_PUBLISH_MAX_TIME_BLOCKED ]] && echo "[ERROR] This publication is not possible because there are other publication activated in $(get_block_directory). Remove $(get_block_directory)/$DP_PUBLISH_LOCK_FILE" && return;
        echo "[INFO] Other artifact is publishing. Waiting $i seconds until $DP_PUBLISH_MAX_TIME_BLOCKED"
        sleep 1
        i=$((i+1))
    done;
   #Remove *.
   local artifact_type=${artifact_regr_expr#*\.}
   local published_artifacts=.dp_published_${artifact_type}
   rm -f $published_artifacts
   #grep -v \".venv" --> Avoid setup.py in virtualenv
   for i in $(find . -name "$artifact_regr_expr"|grep -v "\.venv/"); do
      echo $(readlink -f $i) >>$published_artifacts
   done;
   [[ ! -f $published_artifacts ]] && _log "[WARNING] There are any artifact to publish" && return 0
   block_publish
   local error_code=0
   publish_${artifact_type}s $published_artifacts
   error_code=$?
   unblock_publish
   rm -f $published_artifacts
   return $error_code
}

function main(){
   local dp_publish_invoke=$0
   # If it's invoke by source ... the $0=-bash
   [ "${dp_publish_invoke:0:1}" != "-" ] \
      && [ "$(basename $0)" == "dp_publish.sh" ] \
      && execute $* && exit $?
}
