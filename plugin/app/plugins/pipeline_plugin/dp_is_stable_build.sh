#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)

###HELP section
dp_help_message='Returns "true" if the scm branch type is release, develop or master, and
returns "false" in the other cases

Usage: dp_is_stable_build.sh'

source $DP_HOME/dp_help.sh $*

###END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/versions/dp_version.sh
# It depends on the scm branch_type
is_stable_branch
