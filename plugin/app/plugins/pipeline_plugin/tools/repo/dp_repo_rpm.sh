#!/bin/bash

[ -z $DP_HOME ] && DP_HOME=$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/tools/versions/dp_version.sh


function help(){
   _message "
Create a rpm with a pipeline rpm repository
Usage:
    $0  <url>


Parameters:
    <url>  url of rpm repository
Example:
    $0 http://develenv.softwaresano.com/develenv/rpms
"
}
function currentDir(){
   DIR=`readlink -f $0`
   DIR=`dirname $DIR`
}
function getHostname(){
   local IP MAC_ADDRESSES temp INTERNALIP i j HOST
   IP=`LANG=C /sbin/ifconfig | grep "inet addr" | grep "Bcast" | awk '{ print $2 }' | awk 'BEGIN { FS=":" } { print $2 }' | awk ' BEGIN { FS="." } { print $1 "." $2 "." $3 "." $4 }'`
   MAC_ADDRESSES=`LANG=C /sbin/ifconfig -a|grep HWaddr|awk '{ print $5 }'`
   if [ "$IP" == "" ]; then
      echo -e "\nNo hay conexión de red. Introduce el nombre o la ip de la máquina: \c"
      read HOST
   else
      local j=0
      for i in $IP; do
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
      if [ "$HOST" == "" ]; then
         # Probablemente sea una conexión wifi, y no tenga asignada un nombre en el DNS
         HOST=`hostname`
         INTERNALIP=`echo $IP|cut -d' ' -f1`
         MAC_ADDRESS=`echo $MAC_ADDRESSES|cut -d' ' -f1`
         # Si no hay un nombre de hosts asignado
         if [ "$HOST" == "" ];then
            # Nos quedamos con la primera IP
            HOST=$INTERNALIP
         fi
      fi
   fi
   echo $HOST
}
function removeLastDevelenvRepoRpm(){
   local rpmHome
   local packagerFile="$DIR/dp_repo_rpm.sh"
   [[ $(dirname $packagerFile) == $DEVELENV_HOME/* ]] && \
   [[ "`id -un`" == "$PROJECT_USER" ]] && \
    rpmHome=$HOME/app/repositories/rpms || rpmHome=$HOME/rpmbuild/RPMS
    chattr -i $rpmHome/noarch/ss-develenv-repo-*.rpm
    # Es necesario borrarlo para que el package lo vuelve a generar
    rm -Rf $rpmHome/noarch/ss-develenv-repo-*.rpm
}
currentDir
if [ "$#" != "1" ]; then
   help
   exit 1
fi
repoURL="$1"
REPO_BUILD_DIR=$HOME/temp/DEVELENVREPO
rm -Rf $REPO_BUILD_DIR
mkdir -p $REPO_BUILD_DIR
removeLastDevelenvRepoRpm
SPEC_FILE="$REPO_BUILD_DIR/repo.spec"
echo SPEC_FILE $SPEC_FILE
lineSeparator=`grep -n "###### SPEC ######" $0|grep -v "grep" |sed s:"\:###### SPEC ######":"":g`
sed 1,${lineSeparator}d $0 > $SPEC_FILE
cd $REPO_BUILD_DIR
if [ "$repoURL" != "" ]; then
   sed -i s#"^%define repo_url .*"#"%define repo_url $repoURL"#g $SPEC_FILE
fi
$DP_HOME/profiles/package/redhat/dp_package.sh  --version "1.0" --release "0.0"
rm -Rf $REPO_BUILD_DIR
exit 0
###### SPEC ######
Name:      ss-develenv-repo
Summary:   Repository rpms
Version:   %{versionModule}
Release:   %{releaseModule}
License:   GPL 3.0
Packager:  ss
Group:     develenv
BuildArch: noarch
BuildRoot: %{_topdir}/BUILDROOT
Requires:  wget
Vendor:    SoftwareSano.com

%define package_name repo
%define project_name develenv
%define pipeline_home /opt/pipeline/%{project_name}/enviroment
%define org_acronynm ss
%define component_home /etc/yum.repos.d
%define yum_repos_dir  %{component_home}
%define repo_url http://localhost/develenv/rpms/
%define modify_package_name false


%description
%{project_name} repository

%prep
_log "Building package %{name}-%{version}-%{release}"
mkdir -p %{buildroot}/etc/yum.repos.d/
cd %{buildroot}/etc/yum.repos.d/
# Repositorio de rpms de %{name}

echo "[ss-%{project_name}]
name=ss-%{project_name}
baseurl=%{repo_url}/\$basearch 
enabled=1
gpgcheck=0" > %{buildroot}/etc/yum.repos.d/%{name}.repo

echo "[ss-%{project_name}-noarch]
name=ss-%{project_name}-noarch
baseurl=%{repo_url}/noarch
enabled=1
gpgcheck=0" > %{buildroot}/etc/yum.repos.d/%{name}-noarch.repo

%files
%defattr(-,%{project_name},%{project_name},-)
%config(noreplace) /etc


%pre
wget %{repo_url}/noarch/repodata/repomd.xml -O /dev/null
if [ "$?" != 0 ]; then
   _log "[ERROR] Desde [$(hostname)] no hay acceso a %{repo_url}"
   exit 1
fi
[ "`grep \"^%{project_name}:\" /etc/passwd`" == "" ] && useradd %{project_name}
sed -i s:"/home/%{project_name}\:/bin/sh":"/home/%{project_name}\:/bin/bash":g /etc/passwd

%post
_log "[INFO] Remove cache rpm directory"
%{__rm} -Rf %{_var}/yum/cache/*

%preun

%postun
_log "[INFO] Remove cache rpm directory"
%{__rm} -Rf %{_var}/yum/cache/*

%clean
[ ${RPM_BUILD_ROOT} != "/" ] && rm -rf ${RPM_BUILD_ROOT}/*
