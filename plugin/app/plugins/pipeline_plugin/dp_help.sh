#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
################################################################################
# Print help if the parameter --help is present
################################################################################
function print_help(){
   while [ "$1" ]
   do
       case $1 in
       --help)
          source $DP_HOME/dp_setEnv.sh
          source $SET_ENV_FILE
          if [ "${dp_help_message}" != "" ]; then
            (IFS='x10';_message "${dp_help_message}")
            #Print the help of the diferent types
            if [ "${dp_help_phase}" != "" ]; then
               local phase_commands=$(cd $DP_HOME/profiles/${dp_help_phase}/;\
                  find . -maxdepth 2 -type f -name "dp_${dp_help_phase}.sh")
               local phase_command
               (IFS='x10';_message "\nFor the $dp_help_phase there are available the next types:\n")
               for phase_command in $phase_commands; do
                    _message "--- [$(dirname $phase_command|cut -d'/' -f2)]"
                    bash $DP_HOME/profiles/${dp_help_phase}/${phase_command} --help
               done
               
            fi
          else
             # If it's help command
             if [ "$(basename $0)" == "dp_help.sh" ]; then
                return;
             fi
            (IFS='x10';_message "This command has not any help")
          fi
          exit 0
           ;;
       *)
           ;;
       esac
       shift
   done
}
print_help $*
#It is the dp_help command
dp_help_invoke=$0
if [ "${dp_help_invoke:0:1}" != "-" ]; then
   if [ "$(basename $0)" == "dp_help.sh" ]; then
      commands=$(cd $DP_HOME;ls dp_*.sh|egrep -v "setEnv.sh")
      dp_help_message="The deployment pipeline commands available are:
   
${commands}
   
Type dp_[command].sh --help to obtain help
"
      print_help --help
   fi
fi