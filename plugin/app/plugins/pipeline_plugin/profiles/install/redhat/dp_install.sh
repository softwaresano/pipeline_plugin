#!/bin/bash
LANG=C
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
develenv_repo_rpm="ss-develenv-repo"
function _message(){
   _error_color="\\033[47m\\033[1;31m"
   _default_log_color_pre="\\033[0m\\033[1;34m"
   _default_log_color_suffix="\\033[0m"
   [[ "$1" =~ "_ERROR]" ]] && messageColor=${_error_color} || messageColor=${_default_log_color_pre}
   echo -en "${messageColor}$1${_default_log_color_suffix}\n"
}

function _log(){
   _message "[`date '+%Y-%m-%d %X'`] $1"
}

function pipelineError(){
   errorMessage="$1"
   _log "[DP_ERROR] $errorMessage"
}

function installationError(){
   errorMessage="$1"
   pipelineError "$errorMessage"
   exit 1
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

function prepareRepos(){
   develenvRepoHost=$1
   exitsRPMRepo=`rpm -qa|grep ${develenv_repo_rpm}`
   if [ "$exitsRPMRepo" != "" ]; then
      reposDevelenv=`cat /etc/yum.repos.d/ss-develenv*.repo|grep -v "^#"|grep "baseurl="|grep "$develenvRepoHost"|sed s:".*/rpms/":"":g|sort|awk ' BEGIN { RS=":"}  { print $1" "$2" "$3 } '`
   fi
   if  [ "$reposDevelenv" != "noarch src x86_64" -o "$exitsRPMRepo" == "" ]; then
      if [ "$exitsRPMRepo" != "" ]; then
         dnf remove ${develenv_repo_rpm} -y
      fi
      dnf install wget -y
      [ $? != 0 ] && installationError "No se puede instalar wget. Comprueba acceso a los repositorios de rpms"
      rpm -Uvh $develenvRepoHost/noarch/${develenv_repo_rpm}-1.0-0.0.noarch.rpm
      [ $? != 0 ] && installationError "No se puede instalar [${repoRpmName}.noarch.rpm]. Comprueba acceso al repo"
      #Problem with proxy. Disable epel
      sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ss-epel-*
   fi
}

function prepareHostDeploy(){
   develenvRepoHost="$1"
   pipelineId="$2"
   organization="$3"
   enviroment="$4"
   deploy_pipeline_dir="/opt/pipeline/$organization/${pipelineId}"
   env_deploy_file=${deploy_pipeline_dir}/enviroment
   [ -f $env_deploy_file ] && [ "`cat ${env_deploy_file}`" != "$enviroment" ] && installationError "La máquina [`hostname`] pertenece al entorno [`cat ${env_deploy_file}`]  y no al entorno [${enviroment}]"
   mkdir -p "${deploy_pipeline_dir}";echo ${enviroment} >${env_deploy_file}
   prepareRepos $develenvRepoHost
}


function getInstalledPackageVersion(){
   nInstall="`grep -n "^Installed Packages" $YUM_INFO_FILE|cut -d':' -f1`"
   [ -z $nInstall ] && echo "" && return 0
   rpm -q --queryformat "[%{VERSION}-%{RELEASE}.%{ARCH}]" $namePackage
}

function getPackageVersionToInstall(){
   nInstall="`grep -n "^Available Packages" $YUM_INFO_FILE|cut -d':' -f1`"
   [ -z $nInstall ] && nInstall="`grep -n "^Installed Packages" $YUM_INFO_FILE|cut -d':' -f1`"
   ! [ -z $nInstall ] &&  sed "1,${nInstall}"d $YUM_INFO_FILE|egrep "^Version|^Release|^Arch"|sort|cut -d':' -f2|awk  ' {print $1} '|awk ' BEGIN { RS="{"} {print $3"-"$2"."$1} '
}

function installInHost(){
   local isArchPresent
   local searchRpmFile
   DP_DIR=.dp_dir
   rm -Rf "$DP_DIR"
   [ $? != 0 ] && installationError "[DP_ERROR] Sólo root o un usuario con permisos de sudo pueden ejecutar $0"
   mkdir -p "$DP_DIR"
   PACKAGES_VERSIONS_FILE=$DP_DIR/packagesToInstall
   PACKAGES_REMOVE_FILE=$DP_DIR/packagesToRemove
   rm -f $PACKAGES_REMOVE_FILE $PACKAGES_VERSIONS_FILE
   YUM_INFO_FILE="$DP_DIR"/yuminfo
   develenvRepoHost="$1"
   packagesToInstall="$2"
   pipelineId="$3"
   organization="$4"
   enviroment="$5"
   prepareHostDeploy ${develenvRepoHost} ${pipelineId} ${organization} ${enviroment}
   dnf -y --enablerepo=ss-develenv-noarch clean metadata
   if [ "$?" != 0 ]; then
      installationError "dnf -y --enablerepo=ss-develenv-noarch clean metadata"
   fi
   #Workaround for Centos 5.8 (In Centos 6.8 doesn't appear the arch)
   rpm -qa >$DP_DIR/allPackages
   grep "\.noarch$" $DP_DIR/allPackages >/dev/null
   [ $? == 0 ] && isArchPresent="true" || isArchPresent="false"
   for package in $packagesToInstall; do
     dnf info $package >${YUM_INFO_FILE}
     [ "$?" != "0" ] && installationError "No se puede encontrar el paquete [$package]" && return 1
     packageVersionToInstall="$(getPackageVersionToInstall)"
     namePackage="`grep -n "^Name" $YUM_INFO_FILE|head -1|awk '{print $3}'`"
     ! [ "$namePackage" == "$package" ] && dnf info $namePackage >$YUM_INFO_FILE
     installedPackageVersion="$(getInstalledPackageVersion)";
     local compareVersion=$packageVersionToInstall
     if [[ "$isArchPresent" == "false" ]]; then
        compareVersion=$(echo $packageVersionToInstall|sed s:"\.[noarch]*[x86_64]*[i686]*[i386]*$":"":g)
     fi
     if [ "$installedPackageVersion" != "" ]; then
         [ "$installedPackageVersion" \> "$compareVersion" ] && echo ${namePackage}-${installedPackageVersion} >> ${PACKAGES_REMOVE_FILE}
     fi
     #Si el paquete no está instalado ya previamente
     [ $"$installedPackageVersion" != "$packageVersionToInstall" ] && echo ${namePackage}-${packageVersionToInstall} >> ${PACKAGES_VERSIONS_FILE}
   done;
   [ -f "$PACKAGES_REMOVE_FILE" ] && dnf remove -y `cat $PACKAGES_REMOVE_FILE`
   ! [ -f "$PACKAGES_VERSIONS_FILE" ] && _log "[DP_WARNING] There aren't any package to install" && return 0
   dnf install -y `cat $PACKAGES_VERSIONS_FILE`
   errorCode="$?"
   [ "$errorCode" != "0" ] && _log "[DP_ERROR] Error deploying `cat $PACKAGES_VERSIONS_FILE|tr '\n' ' '`" && exit $errorCode
   rm -Rf $DP_DIR/notInstalled
   rpm -qa >$DP_DIR/allPackages
   for rpmFile in $packagesToInstall; do
      [ "$isArchPresent" == "true" ] && searchRpmFile=$rpmFile || searchRpmFile=$(echo $rpmFile|sed s:"\.[noarch]*[x86_64]*[i686]*[i386]*$":"":g)
      grep "^${searchRpmFile}" $DP_DIR/allPackages
      errorCode=$?
      [ $errorCode != 0 ] && echo $rpmFile >> $DP_DIR/notInstalled
      [ $errorCode == 0 ] && dnf info $rpmFile|egrep "^Name|^Version|^Release|^Arch"|sort|cut -d':' -f2|awk  ' {print $1} '|awk ' BEGIN { RS="{"} {print $2"="$4"-"$3"."$1} ' >> $DP_DIR/packagesInstalled
   done;
   [ -f $DP_DIR/notInstalled ] && _log "[DP_ERROR] Error deploying `cat $PACKAGES_VERSIONS_FILE`|tr '\n' ' '" && exit 1
   _log "[DP_INFO] SUCCESS INSTALLATION" && cat $DP_DIR/packagesInstalled
}

[ "$(id -un)" != "root" ] && pipelineError "Sólo root puede ejecutar $0" && exit 1
