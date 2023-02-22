#!/bin/bash
#Publish all artifacts stored in the tree directory. At the moment only rpms
[ -z $DP_HOME ] && export DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $(which dp_package.sh)/..)
### HELP section
dp_help_message='Copy a source to target directory. This copy assures that nobody is publishing any artifact

Usage: dp_copy_artifacts.sh <source> <target_dir>'

source $DP_HOME/dp_help.sh $*
### END HELP section


source $DP_HOME/profiles/publish/default/dp_publish.sh

function get_repo_dir(){
   local source_file=$1
   local repo_rpm_home=
   [[ "$TEST_REPO_RPM_HOME" == "" ]] && repo_rpm_home=$REPO_RPM_HOME || repo_rpm_home=$TEST_REPO_RPM_HOME
   local relative_file=$(echo $source_file|grep "^${repo_rpm_home}/"|sed s:"${repo_rpm_home}/":"":g)
   if [ "$relative_file" == "" ]; then
      echo ""
      return 1
   fi
   echo $repo_rpm_home/$(echo $relative_file|awk -F "/" '{print $1"/"$2"/"$3}')
}

function get_block_directory(){
   echo ${DP_BLOCK_PUBLISH_DIRECTORY}/$(get_repo_dir $1)
}

function is_blocked() {
    local block_directory=$1
    if [ -f ${DP_BLOCK_PUBLISH_DIRECTORY}/$block_directory/$DP_PUBLISH_LOCK_FILE ] || [ -f /var/develenv/repositories/environments/extra_components/synchronizing ] || [ -f /var/develenv/repositories/environments/qacdn-dev/synchronizing ] ; then
       echo "true"
    else
       echo "false"
    fi
}

# When starts the publication of an artifact, block repo
function block_publish(){
    local repo_directory=$(get_repo_dir $1)
    if [ "$repo_directory" == "" ]; then
       _log "[ERROR] The artifact $1 doesn´t belong to a repo artifacts"
       exit 1
    fi
    _log "[INFO] Avoid new publications in $block_directory directory"
    local block_directory=$(get_block_directory $1)
    mkdir -p $block_directory
    echo "" > $block_directory/$DP_PUBLISH_LOCK_FILE
}

# When ends the publication of an artifact, unblock repo
function unblock_publish(){
    local block_directory=$(get_block_directory $1)
    _log "[INFO] Enable new publications in $block_directory directory"
    rm -f $block_directory/$DP_PUBLISH_LOCK_FILE
}

function copy_repodata(){
  local source_file=$1
  local target=$2
  local type=$3
  local target_repodata="${target}/${type}/repodata"
   if [[ -d $target_repodata ]]; then
      _log "[INFO] Copying ${source_file}/${type}/repodata to ${target_repodata}"
      rm -Rf "$target_repodata"
      cp -r "${source_file}/${type}/repodata" "${target_repodata}"
   fi
}

function copy_artifact(){
    local source_file=$1
    local target=$2
    if ! [ -a "$source_file" ]; then
       _log "[ERROR] The $source_file does not exists"
    fi
    local i=$DP_PUBLISH_MAX_TIME_BLOCKED
    while [[ "$(is_blocked $source_file)" == "true" ]]; do
        [[ 0 -gt $i ]] && \
           _log "[ERROR] $source_file has not been published because the $target directory is blocked. Remove ${DP_BLOCK_PUBLISH_DIRECTORY}/$source_file/$DP_PUBLISH_LOCK_FILE, /var/develenv/repositories/environments/qacdn-dev/synchronizing and /var/develenv/repositories/environments/extra_components/synchronizing" && \
           return 1;
        _log "[INFO] Other artifact is publishing. Waiting $i seconds"
        sleep 1
        i=$((i-1))
    done;
    block_publish $source_file
    # Copy with hard links
    # Ensure that parent target exists
    rm -rf $target
    mkdir -p $(dirname $target)
    cp -rl $source_file $target
    copy_repodata "${source_file}" "${target}" 'initiative/noarch'
    copy_repodata "${source_file}" "${target}" 'initiative/x86_64'
    copy_repodata "${source_file}" "${target}" '3party'
    # Remove extra metadata
    rm -rf $target/.dependencies $target/ur\@* $target/initiative/.noarch $target/initiative/.x86_64
    local error_code=$?
    unblock_publish $source_file
    [ $error_code != 0 ] && _log "[ERROR] Unable to copy in $target" && exit $error_code
    _log "[INFO] $source_file successfully published"
}

function check_parameters(){
    if [ $# != 2 ]; then
        _log "[ERROR] Incorrect parameters"
        dp_copy_artifacts.sh --help
        exit 1
    fi
}

check_parameters $*

copy_artifact $1 $2

