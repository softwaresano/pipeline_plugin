#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
dp_help_message='This command returns the scm branch type. Returns:
unstable
release
develop
master
other

At the moment this command only is implemente for git scm. In the others scm
always returns master

Usage: dp_branch_type.sh'

source $DP_HOME/dp_help.sh $*
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/versions/dp_version.sh
# Returns type of scm branch
get_scm_branch_type