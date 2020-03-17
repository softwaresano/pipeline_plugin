#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)
###HELP section
dp_help_message='Returns the os major release.
Examples:
    Redhat/Centos 5.5: el5
    Redhat/Centos 6.3: el6
    Redhat/Centos 7.0: el7
    Default: uname -rs


Usage: dp_os_release.sh'

source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/versions/dp_version.sh
get_os_release
