#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)
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
extra_config=$(cat .clocrc 2>/dev/null)
mkdir -p target/reports
>target/reports/cloc.txt
$DP_HOME/profiles/metrics/tools/cloc.pl HEAD \
    --read-lang-def="$DP_HOME/profiles/metrics/tools/cloc_extra_languages.txt" \
    --out=target/reports/cloc.txt \
    --fullpath ${extra_config}
   

cat target/reports/cloc.txt

$DP_HOME/profiles/metrics/tools/cloc.pl HEAD \
    --read-lang-def="$DP_HOME/profiles/metrics/tools/cloc_extra_languages.txt" \
    --by-file --xml --out=target/reports/cloc.xml \
    --fullpath ${extra_config}

#Sloccount format for jenkins
sloccount_file="target/reports/sloccount.sc"
xsltproc $DP_HOME/profiles/metrics/tools/cloc2sloccount.xsl \
        target/reports/cloc.xml > $sloccount_file
post_cloc $*
