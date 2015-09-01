#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1

source $DP_HOME/tools/repo/dp_publishArtifactConf.sh
function publishInOtherRepo(){
   [[ "$REMOTE_HOST_REPO" == "" ]] && return 0;
   local develenv_repo=/home/develenv/app/repositories/rpms/noarch/ss-develenv-repo-1.0-0.0.noarch.rpm
   local SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
   local SSH_COMMAND="ssh $SSH_OPTIONS"
   local SCP_COMMAND="scp $SSH_OPTIONS"
   local rpmFile=$1
   if [[ "$rpmFile" != "$develenv_repo" ]]; then
      publishInOtherRepo $develenv_repo
   fi
   local name="nnn"
   local arch=""
   local contador=0
   local rpmName=$(echo $rpmFile|sed s:"\.rpm$":"":g)
   until [ "$name" == "" ]; do
      contador=`expr $contador + 1`
      arch=$name
      name=$(echo $rpmName|cut -d'.' -f$contador)
   done
   $SSH_COMMAND ${REMOTE_USER_REPO}@$REMOTE_HOST_REPO "mkdir -p $REMOTE_TARGET_DIR/$arch"
   $SCP_COMMAND $rpmFile ${REMOTE_USER_REPO}@${REMOTE_HOST_REPO}:$REMOTE_TARGET_DIR/$arch
   $SSH_COMMAND ${REMOTE_USER_REPO}@$REMOTE_HOST_REPO "createrepo -s sha -d --update $REMOTE_TARGET_DIR/$arch"
}

