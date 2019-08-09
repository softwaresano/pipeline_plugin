#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
###HELP section
dp_help_message='Review branch name and last commit message. Only works in git repos"

Usage: dp_scm_compliant.sh

'

source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/scm/dp_scm_compliant.sh
