#!/bin/bash
if [[ -z "$DP_HOME" ]]; then
   DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $(which dp_package.sh 2>/dev/null)/..)
   [[ -z "$DP_HOME" ]] && echo "[ERROR] DP_HOME must be defined" && exit 1
fi

### HELP section
dp_help_message='This command has not any help

Usage: dp_COMMAND.sh'

source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

source $DP_HOME/tools/repo/dp_publishArtifactConf.sh
set +e
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

# Flag to test if the PIPELINE is running
touch $DP_HOME/temp/$PIPELINE_ID


function pipelineError(){
   errorMessage="$1"
   _log "[ERROR] $errorMessage"
}

function pipelineWarning(){
   warningMessage="$1"
   _log "[WARNING] $warningMessage"
}

function exitError(){
   pipelineError "$1"
   if [ $2 != "" ]; then
      [[ "$2" == "0" ]] && publishStateLog ok || publishStateLog ko
      exit $2
   else
      publishStateLog ko
      exit 1
   fi
}

function exitPipeline(){
   local errorCode=$1
   [[ "$errorCode" == "0" ]] && publishStateLog ok || publishStateLog ko
   exit $errorCode
}

function sshCommand(){
   $SSH_COMMAND $*
}

function scpCommand(){
   $SCP_COMMAND $*
}

function getParentJob(){
   if [ "$#" == "0" ]; then
      whatJob=$SIMPLE_JOB_NAME
   else
      whatJob=$1
   fi
   nparentJobs=`curl -k "${URL_JENKINS_JOB}/${whatJob}/api/xml?xpath=count(//upstreamProject)" 2>/dev/null`
   if [ "$nparentJobs" == "1.0" ]; then
      parentJob=`curl -k "${URL_JENKINS_JOB}/${whatJob}/api/xml?xpath=//upstreamProject/name/text%28%29" 2>/dev/null`
   else
      if [ "$nparentJobs" == "0.0" ]; then
         # Ya es el proyecto padre
         parentJob=""
      fi
   fi
}

function getRootJob(){
   getParentJob $1
   if [ "$parentJob" != "" ]; then
     rootJobName=$parentJob
     getRootJob $parentJob
   fi
}

function getActionParameters(){
   local whatJob=$1
   local nAction=1
   local url=${URL_JENKINS_JOB}/${whatJob}/lastBuild/api/xml?xpath=
   [ "`curl -I \"${url}count(//action/parameter/name)\" 2>/dev/null|grep \"HTTP/\"|head -1|grep \"OK\"`" == "" ] && return ;
   local nParameters=$(curl -k "${url}count(//action/parameter/name)" 2>/dev/null)
   [[ "$nParameteres" == "0.0" ]] && return;
   nParameters=$(echo $nParameters|sed s:"\.0$":"":g)
   local nActions=$(curl -k "${url}count(//action)" 2>/dev/null|sed s:"\.0$":"":g)
   local n=1
   local index="1"
   #Buscamos cuál de las acciones tiene definido el parámetro
   while [ $nActions -ge $n -a \
        "$(curl -k "${url}count(//action\[$n\]/parameter/name)" 2>/dev/null|\
        sed s:"\.0":"":g)" == "0" ]
   do
      n=$[$n+1]
      index=$n
   done
   echo $index $nParameters
}

function getParametersJob(){
   local whatJob
   local n
   local actionWithParameters
   local totalParameters
   if [ "$#" == "0" ]; then
      whatJob=$SIMPLE_JOB_NAME
   else
      whatJob=$1
   fi
   jobParameters=""
   actionWithParameters=$(getActionParameters $whatJob)
   [[ "$actionWithParameters" == "" ]] && return;
   totalParameters=$(echo $actionWithParameters|awk '{print $2}')
   actionWithParameters=$(echo $actionWithParameters|awk '{print $1}')
   n=1
   while [ $totalParameters -ge $n ]
   do
     tmpParameters=`curl -k "${URL_JENKINS_JOB}/${whatJob}/lastBuild/api/xml?xpath=//action\[${actionWithParameters}\]/parameter\[${n}\]" 2>/dev/null`
     jobParameters="$jobParameters $tmpParameters"
     jobParameters=`echo $jobParameters|sed s:"^ ":"":g`
     n=$[$n+1]
   done
}

function getParameterJob(){
   if [ "$#" == "1" ]; then
      whatJob=$SIMPLE_JOB_NAME
      paramName="$1"
   else
      whatJob="$1"
      paramName="$2"
   fi
   getParametersJob ${whatJob}
   parameterValue=`echo $jobParameters|sed s:".*<parameter><name>${paramName}</name><value>":"":g|sed s:"<.*":"":g`
}

function copyWorkspace(){
   rm -Rf $WORKSPACE
   [ -d $HUDSON_HOME/jobs/$currentParentJob/workspace ] && cp -R $HUDSON_HOME/jobs/$currentParentJob/workspace  $HUDSON_HOME/jobs/$SIMPLE_JOB_NAME || exitError "No existe el workspace del proyecto padre [$currentParentJob]. Se ha de ejecutar primero el job [$currentParentJob] " 1
}

function moveWorkspace(){
   rm -Rf $WORKSPACE
   # Si es un proyecto multiconfiguración
   if [ "$JOB_NAME" != "$SIMPLE_JOB_NAME" ]; then
      rm -Rf $WORKSPACE
      mkdir -p $HUDSON_HOME/jobs/$SIMPLE_JOB_NAME/workspace/`echo $JOB_NAME|cut -d'=' -f1|sed s:".*/":"":g`
      cp -R $HUDSON_HOME/jobs/$currentParentJob/workspace/ $HUDSON_HOME/jobs/$SIMPLE_JOB_NAME/workspace/`echo $JOB_NAME|sed s:".*/":"":g|sed s:"=":"/":g`
      cd $WORKSPACE
      for ws in `ls -a |grep -v "\.$"`; do
         cp -R $ws ../../
      done
   else
      mv $HUDSON_HOME/jobs/$currentParentJob/workspace/ $HUDSON_HOME/jobs/$SIMPLE_JOB_NAME
   fi
   mkdir -p $HUDSON_HOME/jobs/$currentParentJob/workspace
   echo "[$currentParentJob] está dentro del deployment pipeline" > $HUDSON_HOME/jobs/$currentParentJob/workspace/README.txt
   echo "El Workspace de [$currentParentJob] ha sido movido a $JENKINS_URL/job/$SIMPLE_JOB_NAME/ws" >> $HUDSON_HOME/jobs/$currentParentJob/workspace/README.txt
}

function cloneParentWorkspace(){
   getParentJob $SIMPLE_JOB_NAME
   currentParentJob=$parentJob
   if [ -z "$currentParentJob" ]; then
      echo "Root job"
      return 0
   fi
   getRootJob $SIMPLE_JOB_NAME
   if [ "$currentParentJob" == "$rootJobName" ]; then
      # Parent Project is root Job
      copyWorkspace
   else
      moveWorkspace
   fi
}

function cloneWorkspace(){
   getParentJob $SIMPLE_JOB_NAME
   [[ "$nparentJobs" > "1.0" ]] && [[ "$phase" != "${INSTALL_PHASE}" ]] && exitError "Imposible clonar el workspace. Hay más de un proyecto padre" 1
   if [[ "$phase" == "${INSTALL_PHASE}" ]]; then
      if [[ "$nparentJobs" > "1.0" ]]; then
         pipelineWarning "El job [$SIMPLE_JOB_NAME] tiene $nparentJobs jobs hijos. Por tanto se utiliza el procedimiento de install por defecto" && cd $WORKSPACE && return 0;
      else
         if ! [ -f "$HUDSON_HOME/jobs/$currentParentJob/workspace/install.sh" ]; then
            return 0;
         fi
      fi
   fi
   if [ `basename $PWD` != "workspace" ]; then
      cloneMultiConfigurationWorkspace
   else
      cloneParentWorkspace
   fi
   cd $WORKSPACE
}

function cloneMultiConfigurationWorkspace(){
   if ! [ -f "../../.clone" ]; then
      cloneParentWorkspace
      touch ../../.clone
   else
      touch ../../.clone
      valueVariable=`basename $PWD`
      cd ..
      variable=`basename $PWD`
      cd ..
      for i in `ls -a |grep -v "$variable"|grep -v "\.$"|grep -v ".clone"`; do
         cp -R $i ${variable}/${valueVariable}
      done;
   fi
   cd $WORKSPACE
}

# En un job multiconfiguración después de cada ejecución copiamos el
# workspace específico al genérico
function postProcessWorkspace(){
   cd $WORKSPACE/../../
   for i in `ls -a |grep -v "$variable"|grep -v "\.$"|grep -v ".clone"`; do
      rm -Rf $i
   done;
   for i in `ls -a |grep -v "$variable"|grep -v "\.$"|grep -v ".clone"`; do
      rm -Rf $i
   done;
}

function getPackageModule(){
   getParentJob $1
}

# Id del build de install que empezó la instalación en le primer entorno
# Normalmente el entorno de CI
function getParentBuildId(){
   local parentBuildId
   local installBuildId
   installBuildId=$1
   parentBuildId=$(grep ",${installBuildId}$" $PIPELINE_FILE_STATE|cut -d'.' -f1)
   [[ "$parentBuildId" =~ ^[0-9]+$ ]] && \
   parentBuildId=$(grep "^${parentBuildId}\..*=ok,${parentBuildId}$"\
   $PIPELINE_FILE_STATE|cut -d'.' -f1)
   [[ "$parentBuildId" =~ ^[0-9]+$ ]] && echo $parentBuildId || \
      echo $installBuildId
}

function preInstall(){
   local nInstallBuildId
   local nBuilds
   local preNBuild
   local parentInstallResult
   mkdir -p ${PIPELINE_DATA_DIR}/
   if [ $? != 0 ]; then
      exitError "No hay permiso de escritura en [${PIPELINE_DATA_DIR}]. No se pueden guardar los datos del pipeline" 1
   fi
   getParameterJob "$SIMPLE_JOB_NAME" "N_BUILD"
   currentBuildNumber=`curl -k "${BUILD_URL}/api/xml?xpath=//number/text%28%29" 2>/dev/null`
   nBuilds=`curl -k "${JOB_URL}/api/xml?xpath=count(//build)" 2>/dev/null`
   if [ "$nBuilds" == "0.0" -o "$parameterValue" == "LAST" -o "$parameterValue" == "" ]; then
      #Es la primera vez que se instala
      numberBuild=$currentBuildNumber
      if [ "$(curl -k "${BUILD_URL}/api/xml?xpath=//action/cause/upstreamBuild" 2>/dev/null|grep "^<upstreamBuild>")" == "" -a "$nBuilds" != "0.0" -a "$parameterValue" == "LAST" ]; then
         preNBuild=$(grep '=ok,' $PIPELINE_FILE_STATE|tail -1|cut -d'.' -f1)
         [[ "$preNBuild" =~ ^[0-9]+$ ]] && numberBuild=$preNBuild
      fi
   else
      nInstallBuildId=`curl -k "$JOB_URL/$parameterValue/api/xml?xpath=//number/text%28%29" 2>/dev/null`
      [[ "$nInstallBuildId" =~ ^[0-9]+$ ]] || exitError "No existe la instalación [$parameterValue]" 1
      numberBuild=$parameterValue
      [ "`curl -k \"$JOB_URL/$numberBuild/api/xml?xpath=//freeStyleBuild/result/text%28%29\" 2>/dev/null`" != "SUCCESS" ] \
         && installationError "La instalación [$JOB_URL/$numberBuild] no acabó \
correctamente. Por tanto no se puede hacer una instalación a partir de esta"
   fi
   getParameterJob "$SIMPLE_JOB_NAME" "ENVIROMENT"
   # Revisamos si hay una ejecución que se ha queado a medias. Sólo puede exitir una instalación en proceso
   sed -i s:"${parameterValue}=installing":"${parameterValue}=ko":g $PIPELINE_FILE_STATE
   if [ -z "`cat $PIPELINE_FILE_STATE|grep \"${numberBuild}\.${parameterValue}=\"`" ]; then
      changePipelineState "${numberBuild}.${parameterValue}=installing,${currentBuildNumber}"
   else
      sed -i s:"${numberBuild}\.${parameterValue}=.*":"${numberBuild}\.${parameterValue}=installing,${currentBuildNumber}":g ${PIPELINE_FILE_STATE}
   fi
}

function getVersionsOfPackagesToInstall(){
   packagesToInstall="$1"
   getParameterJob "$SIMPLE_JOB_NAME" "N_BUILD"
   N_BUILD=$parameterValue
   if [ "$N_BUILD" != "LAST" ] && [ "$N_BUILD" != "" ]; then
      packagesToInstall=""
      for packageToInstall in $1; do
          packagesToInstall="${packagesToInstall} ${packageToInstall}-`cat ../builds/${N_BUILD}/archive/${2}|grep \"$packageToInstall=\"|cut -d'=' -f2`"
      done;
   fi
}

function changePipelineState(){
   local deploymentEntry=$1
   local newState=$2
   local deploymentEntryValue
   if [ $# == "1" ]; then
      echo $deploymentEntry >> $PIPELINE_FILE_STATE
   else
      deploymentEntryValue=`grep ${deploymentEntry} ${PIPELINE_FILE_STATE}|awk ' BEGIN {FS=","}  { print $2 } '`
      if [ "$deploymentEntryValue" != "" ]; then
         sed -i s:"${deploymentEntry}=.*":"${deploymentEntry}=$newState,$deploymentEntryValue":g ${PIPELINE_FILE_STATE}
      else
         sed -i s:"${deploymentEntry}=.*":"${deploymentEntry}=$newState":g ${PIPELINE_FILE_STATE}
      fi
   fi
}

function installationError(){
   errorMessage="$1"
   pipelineError "$errorMessage"
   postInstall $NOK
   rm -Rf $PACKAGES_VERSIONS_FILE
   exitPipeline 1
}

function getHostname(){
   IP=`LANG=C /sbin/ifconfig | grep "inet addr" | grep "Bcast" | awk '{ print $2 }' | awk 'BEGIN { FS=":" } { print $2 }' | awk ' BEGIN { FS="." } { print $1 "." $2 "." $3 "." $4 }'`
   MAC_ADDRESSES=`LANG=C /sbin/ifconfig -a|grep HWaddr|awk '{ print $5 }'`
   if [ -z "$IP" ]; then
      echo -e "\nNo hay conexión de red. Introduce el nombre o la ip de la máquina: \c"
      read HOST
   else
      j=0
      for i in $IP;do
         #Averiguamos si alguna IP tiene asignada nombre de red
         j=$(($j +1 ));
         temp=`LANG=C nslookup $i|grep "name = "|cut -d= -f2| sed 's/.//' | sed 's/.$//'`
         if [ "$temp" != "" ]; then
            HOST=$temp
            INTERNALIP=$i
            MAC_ADDRESS=`echo $MAC_ADDRESSES|cut -d' ' -f$j`
            # Avoid problem with virtuals ips
            if [ "$(echo $temp|cut -d'.' -f1)" == "$(echo $(hostname)|cut -d'.' -f1)" ]; then
                break
            fi
         fi
      done
      if [ -z "$HOST" ]; then
         # Probablemente sea una conexión wifi, y no tenga asignada un nombre en el DNS
         HOST=`hostname`
         INTERNALIP=`echo $IP|cut -d' ' -f1`
         MAC_ADDRESS=`echo $MAC_ADDRESSES|cut -d' ' -f1`
         # Si no hay un nombre de hosts asignado
         if [ -z "$HOST" ];then
            # Nos quedamos con la primera IP
            HOST=$INTERNALIP
         fi
      fi
   fi
}

function isSuccessInstallation(){
   grep -n "\[DP_INFO\] SUCCESS INSTALLATION" consoleOutput|cut -d':' -f1|tail -1
}


function defaultInstall(){
   DEPLOYMENT_EXECUTIONS_FILE="$DEPLOYMENT_DIR/${ENVIROMENT}_executions.txt"
   DEPLOYMENT_INSTALLATIONS_PREFIX_FILE="$DEPLOYMENT_DIR/${ENVIROMENT}_installations.txt"
   PACKAGES_VERSIONS_FILE="${DEPLOYMENT_DIR}/packageVersionsInstalled.txt"
   DP_INSTALL_FILE="dp_install_${PIPELINE_ID}.sh"
   getHostname
   rm -Rf $DEPLOYMENT_DIR
   mkdir -p $DEPLOYMENT_DIR
   >${PACKAGES_VERSIONS_FILE}
   cp ${DEPLOYMENT_TABLE_DIR}/${DEPLOYMENT_SIMPLE_FILE_NAME} $DEPLOYMENT_FILE
   HOSTS=`cat ${DEPLOYMENT_FILE} |grep -v "^#"|grep "^${ENVIROMENT}"|cut -d'|' -f2|awk '{ print $1 }'`
   organization=`cat ${DEPLOYMENT_FILE} |egrep "^# Organization:"|cut -d':' -f2|awk '{ print $1 }'`
   project=`cat ${DEPLOYMENT_FILE} |grep "^# Project:"|cut -d':' -f2|awk '{ print $1 }'`
   adminUser=`cat ${DEPLOYMENT_FILE} |grep "^# AdminUser:"|cut -d':' -f2|awk '{ print $1 }'`
   [ -z $adminUser ] && adminUser="root"
   prefixPackages="${organization}-${project}-"
   preInstall
   executeScript "pre" "$1"
   [[ $? != 0 ]] && installationError "Error en la ejecución del script de preInstall" 1
   for deployHost in $HOSTS; do
      packages=`cat $DEPLOYMENT_FILE |grep -v "^#"|grep "$deployHost"|grep "^$ENVIROMENT"|cut -d'|' -f3|sed s:"^ ":"":g|sed s:" $":"":g|sed s:",":" ":g|sed s:"  *":" ":g`
      getVersionsOfPackagesToInstall "${packages}" "${PACKAGES_VERSIONS_FILE}"
      if [ "$packagesToInstall" != "" ]; then
         cp $DP_HOME/profiles/install/redhat/dp_install.sh ${DP_INSTALL_FILE}
         chmod u+x ./${DP_INSTALL_FILE}
         #Agregando debug en el script de instalación
         [ "$DEBUG_PIPELINE" == "TRUE" ] && echo "set -x" >>${DP_INSTALL_FILE}
         local develenv_repo_host
         if [ "$ARTIFACT_REPOSITORY_URL" != "" ]; then
            develenv_repo_host=$ARTIFACT_REPOSITORY_URL
         else
            [[ "$REMOTE_HOST_REPO" == "" ]] && develenv_repo_host="http://$HOST/develenv/rpms" || develenv_repo_host="http://$REMOTE_HOST_REPO/develenv/rpms"
         fi
         echo installInHost \"${develenv_repo_host}\" \"$packagesToInstall\" \"${PIPELINE_ID}\" \"${organization}\" \"$ENVIROMENT\" >>${DP_INSTALL_FILE}
         sshCommand ${adminUser}@${deployHost} "rm -Rf ./${DP_INSTALL_FILE}"
         scpCommand ${DP_INSTALL_FILE} ${adminUser}@${deployHost}:
         sudoCommand=""
         [ "$adminUser" != "root" ] && sudoCommand="sudo "
         _log "[INFO] Deploying in ${deployHost}"
         sshCommand ${adminUser}@${deployHost} "${sudoCommand}./${DP_INSTALL_FILE}">consoleOutput
         # Comprobamos que la instalación ha sido correcta
         [ "$?" != 0 ] && _log "[ERROR] Installation Fault" && cat consoleOutput && installationError "No se puede/n instalar el/los paquetes \"$packagesToInstall\" en  ${deployHost}" || _log "[INFO] \"$packagesToInstall\" deployed in ${deployHost}" && cat consoleOutput
         if [ "$(isSuccessInstallation)" != "" ]; then
            sed 1,$(grep -n "\[DP_INFO\] SUCCESS INSTALLATION" consoleOutput |cut -d':' -f1|tail -1)d consoleOutput|grep ".*=.*" >> ${PACKAGES_VERSIONS_FILE}
            #In Red Hat 5.8 (and maybe other RHEL versions) we need to remove \r at the end of lines
            sed -i  s:"\\r":"":g ${PACKAGES_VERSIONS_FILE}
         fi
      fi
      [ "`cat ${PACKAGES_VERSIONS_FILE}|wc -l`" == "0" ] && pipelineWarning "No hay ningún paquete para instalar en el entorno[$ENVIROMENT]. Quizás ya estaban instalados esta misma versión de los paquetes."
   done;
   executeScript "post" "$OK"
   [[ $? == "0" ]] && postInstall $OK || installationError "Error en la ejecución del script de post instalación"
}

function executeScript(){
   local scriptName=$1-${PHASE_PROJECT}
   local result=$2
   if [ -f "./${scriptName}.sh" ]; then
      if [ -x "./${scriptName}.sh" ]; then
         ./${scriptName}.sh $result
         return $?
      else
         pipelineError "[$scriptName.sh] script has been delivered to the repo witouth execution permissions"
         return 1
      fi
   fi
   return 0
}

function default_phase(){
   if [ -f "$DP_HOME/dp_${PHASE_PROJECT}.sh" ]; then
      executeScript "pre" || exitError "[ERROR] Failed the execution of [pre-${PHASE_PROJECT}]" 1
      $DP_HOME/dp_${PHASE_PROJECT}.sh
      local error_code=$?
      if [[ $error_code == 0 ]]; then
         executeScript "post" "$OK" || _log "[WARNING] Failed the execution of [post-${PHASE_PROJECT} $OK]"
      else
         executeScript "post" "$NOK" || _log "[WARNING] Failed the execution of [post-${PHASE_PROJECT} $NOK]"
      fi
      exitPipeline $error_code
   else
     exitError "[$PHASE_PROJECT] phase is not defined in the deployment pipeline." 1
   fi
}

function build(){
   default_phase
}

function package(){
   default_phase
}

function install(){
   if [ -f "./${PHASE_PROJECT}.sh" ]; then
      if [ -x "./${PHASE_PROJECT}.sh" ]; then
         preInstall
         ./${PHASE_PROJECT}.sh
         errorCode=$?
         if [ "$errorCode" == "0" ]; then
            postInstall $OK
         else
            postInstall $NOK
         fi
      else
            exitError "El script [$PHASE_PROJECT.sh] ha sido entregado al repositorio sin permisos de ejecución" 1
      fi
   else
      defaultInstall
   fi
}

function postInstall(){
   isOk=$1
   getParameterJob "$SIMPLE_JOB_NAME" "ENVIROMENT"
   if [ "$isOk" == "$OK" ]; then
      changePipelineState "${numberBuild}\.${parameterValue}" "installed"
   else
      changePipelineState "${numberBuild}\.${parameterValue}" "ko"
   fi
}


function prePhaseTest(){
   local state
   phaseTest=$1
   echo "[INFO] pre${phaseTest}"
   getParameterJob "${INSTALL_JOB_ID}" "N_BUILD"
   if [ "$parameterValue" == "LAST" ]; then
      [ "$phaseTest" == "smokeTest" ] && state="installed" || \
         state="smokeTestExecuted"
      numberBuild=$(grep "=${state}," $PIPELINE_FILE_STATE|tail -1|cut -d'.' -f1)
   else
      numberBuild=$parameterValue
   fi
   [[ "$numberBuild" =~ ^[0-9]+$ ]] || exitError "No existe ninguna instalación exitosa" 1   
   getParameterJob "${INSTALL_JOB_ID}" "ENVIROMENT"
   # Revisamos si hay una ejecución de tests que se ha quedado a medias. Sólo puede exitir una ejecución en proceso
   sed -i s:"${parameterValue}=${phaseTest}Execution":"${parameterValue}=ko":g $PIPELINE_FILE_STATE
   changePipelineState "${numberBuild}\.${parameterValue}" "${phaseTest}Execution"
   TEST_DEPLOYMENT_FILE="$WORKSPACE/target/deployment"
   rm -Rf $TEST_DEPLOYMENT_FILE
   mkdir -p $(dirname $TEST_DEPLOYMENT_FILE)
   enviromentId=$parameterValue
   local test_job_id=`ls $DEVELENV_HOME/app/jenkins/jobs|grep "${PIPELINE_ID}-.*-${phaseTest}"`
   get_deployment_table "$HUDSON_HOME/jobs/$test_job_id/config.xml" "$TEST_DEPLOYMENT_FILE"
}

function pipeline2JUnit(){
   local phaseTest=$1
   local prefixFileName="target/TESTS-pipeline/${phaseTest}/TEST-pipeline-${PIPELINE_ID}"
   local input=${prefixFileName}.txt
   local output=${prefixFileName}.xml
   local logFile=$DEVELENV_HOME/app/jenkins/jobs/$SIMPLE_JOB_NAME/builds/$BUILD_NUMBER/log
   local testSuiteName=${PIPELINE_ID}
   local ntest testOk testFailed testSkipped testError
   rm -Rf $(dirname $prefixFileName)
   mkdir -p $(dirname $prefixFileName)
   grep "${phaseTest}\[" $logFile|sed s:".*${phaseTest}\[":"${phaseTest}\[":g >$input
   [ "$(cat $input|wc -l)" == 0 ] && \
      _log "[WARNING] No hay test en formato pipeline"\
      return 

   ntests=$(grep "^${phaseTest}\[" $input|wc -l)
   testOk=$(grep " Success$" $input|wc -l)
   testFailed=$(grep " Fail$" $input|wc -l)
   testSkiped=$(grep " Skip$" $input|wc -l)
   testError=$(grep " Error$" $input|wc -l)
   echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
   <testsuite failures=\"$testFailed\" errors=\"$testError\" skipped=\"$testSkiped\"
              tests=\"$ntests\" name=\"pipeline.${testSuiteName}.$phaseTest\">
   " >$output
   grep -v "Skip$" $input|sed s:"Skip$":"":g|\
      sed s:"^$phaseTest\[$phaseTest":"   <testcase name=\"":g >> $output
   echo "</testsuite>" >>$output
   sed -i s:"\] *Fail$":"\"><error message=\"error\"/></testcase>":g $output
   sed -i s:"\] *Error$":"\"><error message=\"error\"/></testcase>":g $output
   sed -i s:"\] *Skip$":"\"><skipped message=\"skipped\"/></testcase>":g $output
   sed -i s:"\] *Skip$":"\"><skipped message=\"skipped\"/></testcase>":g $output
   sed -i s:"\] *Success$":"\"/>":g $output
}

function postPhaseTest(){
   local phaseTest=$1
   local isOk=$2
   echo "[INFO] post${phaseTest}"
   pipeline2JUnit $phaseTest
   getParameterJob "${INSTALL_JOB_ID}" "ENVIROMENT"
   if [ "$isOk" == "$OK" ]; then
      if [ $phaseTest == "smokeTest" ]; then
         changePipelineState "${numberBuild}\.${parameterValue}" "smokeTestExecuted"
      else
         changePipelineState "${numberBuild}\.${parameterValue}" "ok"
      fi
   else
      changePipelineState "${numberBuild}\.${parameterValue}" "ko"
   fi
}

function phaseTest(){
   phaseTest=$1
   prePhaseTest $phaseTest
   phaseTestsParameters="-e $enviromentId"
   if [ -f $TEST_DEPLOYMENT_FILE ]; then
      phaseTestsParameters="$phaseTestsParameters -t $TEST_DEPLOYMENT_FILE"
   fi
   if [ "${phaseTest}" == "smokeTest" ]; then
      local sleepSeconds=150
      if [[ "$pauseSeconds" != "" ]]; then
          sleepSeconds=$pauseSeconds
      fi
      phaseTestsParameters="$phaseTestsParameters -p $sleepSeconds"
   elif [ "${phaseTest}" == "acceptanceTest" ]; then
      local sleepSeconds=0
      if [[ "$pauseSeconds" != "" ]]; then
          sleepSeconds=$pauseSeconds
      fi
      phaseTestsParameters="$phaseTestsParameters -p $sleepSeconds"
   fi
   if  [ -f ${phaseTest}.sh ]; then
      ./${phaseTest}.sh $phaseTestsParameters
      errorCode=$?
   else
      postPhaseTest ${phaseTest} $NOK
      exitError "No hay ${phaseTest} definidos." 1
   fi
   if [ "$errorCode" == "0" ]; then
      postPhaseTest ${phaseTest} $OK
   else
      postPhaseTest ${phaseTest} $NOK
      exitError "Error en la ejecución de [${phaseTest}]" $errorCode
   fi
}
function smokeTest(){
   phaseTest smokeTest
}

function acceptanceTest(){
   phaseTest acceptanceTest
}

function exportRepos(){
   local installBuildId
   getParentJob $SIMPLE_JOB_NAME
   getParameterJob "$parentJob" "N_BUILD"
   currentBuildNumber=`curl -k "${BUILD_URL}/api/xml?xpath=//number/text%28%29" 2>/dev/null`
   numberBuild=$parameterValue
   if [ "$numberBuild" == "LAST" ]; then
      installBuildId=`curl -k $URL_JENKINS_JOB/${INSTALL_JOB_ID}/api/xml?xpath=//lastSuccessfulBuild/number/text%28%29 2>/dev/null`
      installBuildId=$(getParentBuildId "$installBuildId")
   else
      installBuildId=$numberBuild
   fi
   [[ "$installBuildId" =~ ^[0-9]+$ ]] || exitError "No se puede exportar \
el repositorio porque no ha habido ninguna instalación correcta en la pipeline\
[$URL_JENKINS_JOB/${INSTALL_JOB_ID}]" 1
   pipelineVersion=`curl -k "$URL_JENKINS_JOB/${INSTALL_JOB_ID}/${installBuildId}/artifact/target/DEPLOYMENT_PIPELINE/deployment.txt" 2>/dev/null|grep "^# Version:"|cut -d':' -f2|awk '{print $1}'`
   [ "$pipelineVersion" == "" ] && exitError "No se puede exportar el\
repositorio. No existe la url [$URL_JENKINS_JOB/${INSTALL_JOB_ID}\
/${installBuildId}/artifact/target/DEPLOYMENT_PIPELINE/deployment.txt].Vuelve a \
ejecutar este Job con un valor para  N_BUILD correcto" 1
   changePipelineState "${installBuildId}.${EXPORT_REPOS_STATE}=exporting,${currentBuildNumber}"
   export installBuildId
   export INSTALL_JOB_ID
   $DP_HOME/exportRepos/package.sh $pipelineVersion $installBuildId
   resultCode=$?
   if [ "$resultCode" != "0" ]; then
      changePipelineState "${installBuildId}\.${EXPORT_REPOS_STATE}" "ko"
      exitError "Error en la exportación del repositorio" $resultCode
   else
      changePipelineState "${installBuildId}\.${EXPORT_REPOS_STATE}" "exported"
   fi
}

function getLastInstallation(){
   local enviroment
   local lastInstallation
   local installJob
   enviroment=$1
   installJob=$2
   lastInstallation=$(grep "${enviroment}=ok," $PIPELINE_FILE_STATE |tail -1|\
                      cut -d'.' -f1)
   [[ "$lastInstallation" != "" ]] && \
      echo "<a href=\"${installJob}/${lastInstallation}/\">${lastInstallation}</a>" || \
      echo "N/A"
}

function isPublicOn(){
   MACHINE_REPORTS="ci-pipeline.hi.inet"
   host $MACHINE_REPORTS >/dev/null
   [[ $? != 0 ]] && return 1
   local thisHost=$(host `hostname`|cut -d' ' -f1)
   local reportHost=$(host $MACHINE_REPORTS|cut -d' ' -f1)
   #if it's the same machine it's not necessary
   [[ "$thisHost" == "$reportHost" ]] && return 1
   grep "replicahi\.hi\.inet" $DEVELENV_HOME/app/jenkins/config.xml
}

function isTriggerCause(){
   local nCause=$1
   local type=$2
   local cause
   if [ "$nCause" == "0" ]; then
      cause=$(curl -k "${URL_JENKINS_JOB}/${SIMPLE_JOB_NAME}/${BUILD_NUMBER}/api/xml?xpath=//cause/${type}/text()" 2>/dev/null)
   else
      cause=$(curl -k "${URL_JENKINS_JOB}/${SIMPLE_JOB_NAME}/${BUILD_NUMBER}/api/xml?xpath=//cause\[$nCause\]/${type}/text()" 2>/dev/null)
   fi
   [[ $cause == XPath\ * ]] && echo "" && return
   [[ "$cause" != "" ]] && echo "${type}(${cause})" && return
}

function getTriggerCause(){
#?xpath=count(//action/cause/upstreamProject) --> Trigger by upstream project
#?xpath=//action/cause/userId --> Trigger by user
   local nCauses=`curl -k "${URL_JENKINS_JOB}/${SIMPLE_JOB_NAME}/${BUILD_NUMBER}/api/xml?xpath=count(//cause)" 2>/dev/null`
   nCauses=$(echo $nCauses|cut -d'.' -f1)
   nCauses=$(expr $nCauses - 1)
   local cause=$(isTriggerCause "$nCauses" userId)
   [[ "$cause" != "" ]] && echo $cause && return;
   cause=$(isTriggerCause $nCauses upstreamProject)
   [[ "$cause" != "" ]] && echo $cause || echo scm
}

function isFinishedTheLastExecution(){
   local idExecution=$(grep "|${SIMPLE_JOB_NAME}-executing|" $PIPELINE_STATUS_LOG_FILE |tail -1|cut -d'|' -f7)
   [[ "$idExecution" == "" ]] && return 0
   local resultId=$(egrep "\|${SIMPLE_JOB_NAME}-ko|${SIMPLE_JOB_NAME}-ok|${SIMPLE_JOB_NAME}-aborted\|" $PIPELINE_STATUS_LOG_FILE|tail -1|cut -d'|' -f7)
   [[ "$resultId" == "" ]] && return $idExecution
   [[ "$resultId" != "$idExecution" ]] && return $idExecution
   return 0
}

function getLastSuccesfullInstallBuildId(){
   getParameterJob "${INSTALL_JOB_ID}" "N_BUILD"
   local n_build=$parameterValue
   [[ "$n_build" == "LAST" ]] && n_build=`curl -k $URL_JENKINS_JOB/${INSTALL_JOB_ID}/api/xml?xpath=//lastSuccessfulBuild/number/text%28%29 2>/dev/null`
   [[ "$n_build" == "Xpath //" ]] && n_build=0;
   echo $n_build
}

function publishStateLog(){
   getHostname
   local enviroment="building($HOST)"
   local stateResult=$1
   local buildNumber=$BUILD_NUMBER
   [[ $# == 2 ]] && buildNumber=$2
   if [ "$stateResult" == "executing" ]; then
      isFinishedTheLastExecution
      local idExecution=$?
      [[ "$?" != $idExecution ]] && publishStateLog "aborted" $idExecution
   fi

   local lastInstallBuildId=0
   local triggerCause=$(getTriggerCause)
   isCommonPhase
   if [ $? == 0 ]; then
      getParameterJob "${INSTALL_JOB_ID}" "ENVIROMENT"
      enviroment=$parameterValue
       # Si es el job de install y se ha lanzado por un job padre significa que empieza una nueva ejecución en la pipeline
       if [ "$PHASE_PROJECT" == "install" ]; then
         if [[ "$triggerCause" == upstreamProject\(* ]]; then
            lastInstallBuildId=$(curl -k "${URL_JENKINS_JOB}/${INSTALL_JOB_ID}/lastBuild/api/xml?xpath=//number/text%28%29" 2>/dev/null)
            [[ "$lastInstallBuildId" =~ ^[0-9]+$ ]] || lastInstallBuildId=-1
         else 
            if [[ "$triggerCause" == userId\(* ]]; then
               lastInstallBuildId=$(getLastSuccesfullInstallBuildId)
               [[ "$lastInstallBuildId" =~ ^[0-9]+$ ]] || lastInstallBuildId=-1
            fi
         fi
       fi
       if [ "$PHASE_PROJECT" == "smokeTest" -o  "$PHASE_PROJECT" == "acceptanceTest" -o "$PHASE_PROJECT" == "exportRepos" ]; then
         lastInstallBuildId=$(getLastSuccesfullInstallBuildId)
         [[ "$lastInstallBuildId" =~ ^[0-9]+$ ]] || lastInstallBuildId=-1
       fi
   fi
   [[ "$PHASE_PROJECT" == "exportRepos" ]] && enviroment=""
   local logLine=
   local logLine="$PIPELINE_ID|$HOST|$(date '+%d/%m/%Y %H:%M:%S')|$enviroment|${SIMPLE_JOB_NAME}-$stateResult|${triggerCause}|$buildNumber|$lastInstallBuildId|"
   echo $logLine  >>$PIPELINE_STATUS_LOG_FILE
   isPublicOn
   [[ "$?" != "0" ]] && return;
   sshCommand develenv@$MACHINE_REPORTS \
      "echo \"$logLine\" >>$PIPELINE_STATUS_LOG_FILE"
}

function getPipelineTaskType(){
   if [ "`echo $ADMIN_PIPELINE_JOBS|grep \"$JOB_NAME\"`" != "" ]; then
       pipelineTaskType="admin"
   else
       pipelineTaskType="execution"
   fi
}

function isCommonPhase(){
   local phase
   for phase in $COMMON_PHASES; do
      [[ "$PHASE_PROJECT" == "$phase" ]] && return 0 
   done;
   return 1
}
# Extract the deployment table from jenkins config job file
function get_deployment_table(){
   local deployment_table_separator="##################### DEPLOYMENT TABLE ############################"
   local job_config=$1
   local deployment_table=$2
   local lineSeparator=`grep -n "$deployment_table_separator" ${job_config}|grep -v "grep" |sed s:"\:$deployment_table_separator":"":g`
   if [ "$lineSeparator" == "" ]; then
      exitError "Definición incorrecta del deployment table. Falta $deployment_table_separator" "1"
   fi
   sed 1,${lineSeparator}d $job_config > ${deployment_table}.tmp
   sed $(cat ${deployment_table}.tmp|grep -n "</command>"|head -1|cut -d':' -f1),20000d ${deployment_table}.tmp > ${deployment_table}
   rm ${deployment_table}.tmp
}

function initDeploymentTable(){
   DEPLOYMENT_DIR="target/$DEPLOYMENT_PREFIX"
   DEPLOYMENT_SIMPLE_FILE_NAME="deployment.txt"
   DEPLOYMENT_FILE="$DEPLOYMENT_DIR/${DEPLOYMENT_SIMPLE_FILE_NAME}"
   EXPORT_JOB_ID=`ls $DEVELENV_HOME/app/jenkins/jobs|grep "${PIPELINE_ID}-EXPORT"`
   DEPLOYMENT_TABLE_DIR=$HUDSON_HOME/jobs/$INSTALL_JOB_ID
   INSTALL_JOB_CONFIG_FILE=$HUDSON_HOME/jobs/$INSTALL_JOB_ID/config.xml
   mkdir -p $DEPLOYMENT_TABLE_DIR/$DEPLOYMENT_DIR
   get_deployment_table "$INSTALL_JOB_CONFIG_FILE" "${DEPLOYMENT_TABLE_DIR}/${DEPLOYMENT_SIMPLE_FILE_NAME}"
   #remove white spaces (begining and end)
   sed -i s:"^ *":"":g ${DEPLOYMENT_TABLE_DIR}/${DEPLOYMENT_SIMPLE_FILE_NAME}
   sed -i s:" *$":"":g ${DEPLOYMENT_TABLE_DIR}/${DEPLOYMENT_SIMPLE_FILE_NAME}
   local projectId=`cat $DEPLOYMENT_TABLE_DIR/${DEPLOYMENT_SIMPLE_FILE_NAME} |grep "^# Project:"|cut -d':' -f2|awk ' { print $1 }'`
   [[ "$PIPELINE_ID" != "$projectId" ]] && cat $DEPLOYMENT_TABLE_DIR/${DEPLOYMENT_SIMPLE_FILE_NAME} && exitError "El campo Project definido en la deployemnt table debería ser $PIPELINE_ID y no $projectId" 1
   ENVIROMENTS="`cat $DEPLOYMENT_TABLE_DIR/${DEPLOYMENT_SIMPLE_FILE_NAME} |grep \"^# Enviroments:\"|cut -d':' -f2|sed s:\"^ \":\"\":g|sed s:\" $\":\"\":g`"
   ARTIFACT_REPOSITORY_URL="`cat $DEPLOYMENT_TABLE_DIR/${DEPLOYMENT_SIMPLE_FILE_NAME} |grep \"^# Artifact repository:\"|sed s*\"^# Artifact repository:\"*\"\"*g|awk '{print $1}'`"
   PIPELINE_REPORT_DIR_HTML="$DEVELENV_HOME/app/sites/pipelines/$PIPELINE_ID"
   PIPELINE_DATA_DIR="$PIPELINE_REPORT_DIR_HTML/data"
   PIPELINE_FILE_STATE="${PIPELINE_DATA_DIR}/pipeline.txt"
   if ! [ -f $PIPELINE_FILE_STATE ]; then
      mkdir -p ${PIPELINE_DATA_DIR}
      > $PIPELINE_FILE_STATE
   fi
   URL_PIPELINE_INSTALL_JOB="`echo $URL_JENKINS_JOB|sed s/":"/"\\\\\:"/g`/${INSTALL_JOB_ID}"
   URL_PIPELINE_EXECUTE_JOB="${URL_PIPELINE_INSTALL_JOB}"
   URL_PIPELINE_EXPORT_JOB="`echo $URL_JENKINS_JOB|sed s/":"/"\\\\\:"/g`/${EXPORT_JOB_ID}"
   EXPORT_REPOS_STATE=exportRepos
}

function init(){
   SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
   SSH_COMMAND="ssh $SSH_OPTIONS"
   SCP_COMMAND="scp $SSH_OPTIONS"
   if [ -z "$PROJECT_HOME" -o -z "$HUDSON_HOME" ] ; then
     # it does not use exitError function because this a execution with develenv
      _log "[ERROR] Pipeline plugin only works with develenv"
      exit 1
   fi
   OK="TRUE"
   NOK="FALSE"
   TRUE="0"
   FALSE="1"
   SIMPLE_JOB_NAME=`echo $JOB_NAME|sed s:"/.*":"":g`
   PIPELINE_ID=`echo $JOB_NAME|cut -d'-' -f1`
   PIPELINE_REPORT_DIR=$DEVELENV_HOME/app/sites/pipelines/data
   PIPELINE_STATUS_LOG_FILE=$PIPELINE_REPORT_DIR/dp_changes.txt
   mkdir -p $PIPELINE_REPORT_DIR
   export PIPELINE_ID
   #Phase: build, package, install ...
   PHASE_PROJECT=`echo $SIMPLE_JOB_NAME|cut -d '-' -f4`
   if [ "$PHASE_PROJECT" == "" ]; then
      if [ "`echo \"${SIMPLE_JOB_NAME}\"|sed s:'.*-EXPORT$':'EXPORT':g`" == "EXPORT" ]; then
         PHASE_PROJECT="exportRepos"
      fi
   fi
   # install phase it's clone if exists install.sh file
   INSTALL_PHASE="install"
   CLONE_PHASES="unitTest integrationTest package ${INSTALL_PHASE} metrics"
   COMMON_PHASES="install smokeTest acceptanceTest exportRepos"
   ADMIN_PIPELINE_JOBS="pipeline-ADMIN-01-addPipeline pipeline-ADMIN-02-addModuleToPipeline pipeline-ADMIN-02-clonePipeline"
   DEPLOYMENT_PREFIX="DEPLOYMENT_PIPELINE"
   URL_JENKINS_JOB="${JENKINS_URL}job"
   INSTALL_JOB_ID=`ls $DEVELENV_HOME/app/jenkins/jobs|grep "${PIPELINE_ID}-.*-install"`
   publishStateLog "executing"
   getPipelineTaskType
   if [ "${pipelineTaskType}" == "execution" ]; then
      initDeploymentTable
   fi
}

function addPipeline(){
   getParameterJob "organization"
   organization="$parameterValue"
   getParameterJob "project"
   project="$parameterValue"
   getParameterJob "version"
   version=$parameterValue
   getParameterJob "modules"
   modules=$parameterValue
   getParameterJob "enviroments"
   enviroments=$parameterValue
   getParameterJob "adminUser"
   adminUser=$parameterValue
   $DP_HOME/admin/pipelineProject.sh "$organization" "$project" "$version" "$modules" \
"$enviroments" "$adminUser"
}

function addModuleToPipeline(){
   getParameterJob "project"
   project="$parameterValue"
   getParameterJob "module"
   module=$parameterValue
   $DP_HOME/admin/pipelineModule.sh "$project" "$module"
}

function clonePipeline(){
   pipelineError "Falta implementar la tarea clonePipeline" 1
}

function adminTask(){
   $PHASE_PROJECT
}


function executionTask(){
   for phase in $CLONE_PHASES; do
      if [ "$PHASE_PROJECT" == "$phase" ]; then
         cloneWorkspace
      fi
   done;
   cd $EXECUTION_DIR
   $PHASE_PROJECT
}

init
# $1 is the relative directory to workspace where the pipeline is executed
if [[ "$1" != "" ]]; then
   _log "[INFO] Pipeline executed in $1 directory"
   EXECUTION_DIR=$1
else
   EXECUTION_DIR=$PWD
fi

${pipelineTaskType}Task
exitPipeline $?