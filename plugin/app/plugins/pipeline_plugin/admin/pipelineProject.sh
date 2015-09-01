#!/bin/bash
if [[ -z "$DP_HOME" ]]; then
   DP_HOME=$(dirname $(readlink -f $(which dp_package.sh 2>/dev/null) 2>/dev/null) 2>/dev/null)
   [[ -z "$DP_HOME" ]] && echo "[ERROR] DP_HOME must be defined" && exit 1
fi

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
. /home/develenv/bin/setEnv.sh
. $DP_HOME/admin/createPipeline.sh
function help(){
   echo "Uso: $0 <organization> <project-name> <version> <module [module]*> <enviroment [enviroment]*> <adminUser> [--help]"
   echo "Creación del deployment pipeline de un proyecto"
   echo ""
   echo ""
   echo "EJEMPLO:"
   echo "    $0 \"ss\" \"webCalculator\" \"1.0\" \"frontend backend\" \"ci qa thirdparty demo\" \"root\"" 
   echo ""
   echo "Más información en http://code.google.com/p/develenv-pipeline-plugin"
}
helpParameter $*
if [ "$#" != 6 ]; then
   errorParameters "Incorrect number of parameters"
   help
else
   createProject "$1" "$2" "$3" "$4" "$5" "$6"
fi


