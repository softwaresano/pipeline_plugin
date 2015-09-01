#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
### HELP section
dp_help_message='Returns the scm info

Usage: dp_scm_info.sh

Output examples:




[subversion]
Path: .
Working Copy Root Path: /Users/carlosg/workspace/pipeline_plugin
URL: https://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin
Repository Root: https://develenv-pipeline-plugin.googlecode.com/svn
Repository UUID: 78ab7bcd-1ddc-bec0-7c6a-e2dfeb1366c4
Revision: 766
Node Kind: directory
Schedule: normal
Last Changed Author: carlosegg
Last Changed Rev: 766
Last Changed Date: 2014-08-21 15:22:36 +0200 (Thu, 21 Aug 2014)

[git]
  == Remote URL:
     git@github.com:jenkinsci/jenkins.git
  == Last Commit:
     0c8a7351863213b56d60f95b0845fed2dfa4412b
'

source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/tools/versions/dp_version.sh
get_scm_info