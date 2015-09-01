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
   echo "Uso: $0 <project-name> <module>[--help]"
   echo "Creación de un módulo dentro del deployment pipeline de un proyecto. Para crear un módulo es necesario que el proyecto esté creado anteriormente."
   echo ""
   echo ""
   echo "EJEMPLO:"
   echo "    $0 \"webCalculator\" \"frontend\" "
   echo ""
   echo "Más información en http://code.google.com/p/develenv-pipeline-plugin"
}

helpParameter $*
if [ "$#" != 2 ]; then
   errorParameters "Incorrect number of parameters"
   help
else
   createModule "$1" "$2"
fi