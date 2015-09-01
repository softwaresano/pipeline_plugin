#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
### HELP section
dp_help_message='cloc counts blank lines, comment lines, and physical lines of source code in many programming languages

Usage: dp_cloc.sh
'

source $DP_HOME/dp_help.sh $*
### END HELP section
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

# Execute and action after rpm is published
function post_cloc(){
   source $DP_HOME/config/dp.cfg
   if [ "$POST_CLOC_SCRIPT" != "" ]; then
      _log "[INFO] Execution post cloc script"
      $POST_CLOC_SCRIPT $*
   fi
}

scm_type=$(dp_scm_type.sh)
default_ignore_dirs=target,.venv
if [ -f .gitignore ]; then
   exclude_dirs=$(cat .gitignore |grep -v "#"|grep -v "*"|grep -v ^$|tr \\n ,)
fi
mkdir -p target/reports
>target/reports/cloc.txt
$DP_HOME/profiles/metrics/tools/cloc-1.62.pl . \
    --out=target/reports/cloc.txt \
     --exclude-dir=${default_ignore_dirs},${exclude_dirs}

cat target/reports/cloc.txt

$DP_HOME/profiles/metrics/tools/cloc-1.62.pl . \
     --by-file --xml --out=target/reports/cloc.xml \
     --exclude-dir=${default_ignore_dirs},${exclude_dirs}
#Sloccount format for jenkins
sloccount_file="target/reports/sloccount.sc"
xsltproc $DP_HOME/profiles/metrics/tools/cloc2sloccount.xsl \
        target/reports/cloc.xml > $sloccount_file
$DP_HOME/profiles/metrics/tools/languages/cloc_extra_languages.sh >> $sloccount_file
post_cloc $*