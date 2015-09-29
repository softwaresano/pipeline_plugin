#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
source $DP_HOME/tools/versions/get_git_version_string.sh

VERSION_FILE="VERSION.txt"

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
function packageError(){
   errorMessage="$1"
   _log "[ERROR] $errorMessage"
}

function exitPackage(){
   if [ "$1" != "" ]; then
      exit $1
   else
      exit 1
   fi
}

function exitError(){
   packageError "$1"
   exitPackage "$2"
}

function scmUrl_git(){
   # If there are two or more remote repo, select origin or the first
   echo "scm:git:"$(git remote -v|grep "(fetch)$"|grep ^origin|head -1|awk '{print $2}')
}

function scmUrl_mercurial(){
   (
    while [ ! -d .hg ] && [ ! "$PWD" = "/" ]; do cd ..; done
    echo "scm:hg:"$(tail -1 .hg/hgrc|sed s:".*=":"":g|awk '{print $1}')
   )
}

function scmUrl_subversion(){
   echo "scm:svn:"$(svn info|grep "^URL:"|awk '{print $2}')
}

function scmUrl_none(){
   echo ""
}

function scm_gitInfo(){
   echo "  == Remote URL:"
   echo "     $(git config remote.origin.url)"
   echo "  == Last Commit:"
   echo "     $(git --no-pager log --max-count=1|\
                           grep ^commit|awk '{print $2}')"
}

function scm_mercurialInfo(){
   if [ -d .hg ]; then
      echo "== Remote URL: `hg paths`"
      echo "== Remote Branches: "
      hg branches
      echo ""
      echo "== Current Branch: "
      hg branch
      echo 
      echo "== Most Recent Commit"
      hg log -l 1 -b `hg branch`
   else
     echo "Not a mercurial repository."
   fi
}

function scm_subversionInfo(){
   svn info
   if [[ "$?" != "0" ]]; then
      _log "[ERROR] Problems in svn info"
      exit 1
   fi
   revision="`echo $(svn info .|egrep "^Revision:"|sed s:"Revision\: ":"":g)`"
   if [ "$(svn propget svn:externals .)" != "" ]; then
      echo "External Links in the root of the repo"
      svn propget svn:externals . > .borrame
      while read line
         do
         url=$(echo $line |awk '{print $1}')
         if [[ "$url" != "" ]]; then
            echo $(svn info $url|egrep "^URL:|^Revision:"|sed s:"URL\: ":"":g|sed s:"Revision\: ":"":g)
            revision="$revision `echo $(svn info $url|egrep "^Revision:"|sed s:"Revision\: ":"":g)`"
         fi
      done < ".borrame"
      rm -Rf .borrame
   fi
}

function scm_noneInfo(){
   echo "[WARNING] this code isn't stored in any scm repository"
}

function get_scm_revision_subversion(){
   revision="`echo $(svn info .|egrep "^Revision:"|sed s:"Revision\: ":"":g)`"
   if [ "$(svn propget svn:externals .)" != "" ]; then
      svn propget svn:externals . > .borrame
      while read line
         do
         url=$(echo $line |awk '{print $1}')
         if [[ "$url" != "" ]]; then
            revision="$revision `echo $(svn info $url|egrep "^Revision:"|sed s:"Revision\: ":"":g)`"
         fi
      done < ".borrame"
      rm -Rf .borrame
   fi
   echo $(expr `echo $revision|sed s:" ":" + ":g`) 
}

function get_default_scm_revision(){
   date '+%Y%m%d_%H%M%S'
}
function get_scm_revision_mercurial(){
   get_default_scm_revision
}

function get_scm_revision_git(){
   if [[ $(is_pdi_compliant) ]]; then
     echo $(get_revision) 
   else
     echo $(date '+%Y%m%d_%H%M%S').$(git --no-pager log --max-count=1|grep "^commit"|awk '{print $2}')
   fi
}

function get_scm_revision_none(){
   get_default_scm_revision
}

function get_scm_branch_type_default(){
   echo "[WARNING] scm_branch_type is not implemented for this $1 scm. master is assigned by default" >/dev/stderr
   echo "master"
}

function get_scm_branch_type_subversion(){
   get_scm_branch_type_default "subversion"
}

function get_scm_branch_type_mercurial(){
   get_scm_branch_type_default "mercurial"
}

function get_scm_branch_type_none(){
   get_scm_branch_type_default "none"
}


function get_scm_branch_type_git(){
   get_branch_type
}

function get_scm_branch_type(){
   get_scm_branch_type_$(getSCM)
}

#It returns true if it's subversion
function is_scm_type(){
   (while [ ! -d "$1" ] && [ ! "$PWD" = "/" ]; do cd ..; done
   if [ -d "$1" ]; then
      echo "true"
   else
      echo "false"
   fi)
}

function getSCM(){
   local source_dir=$PWD
   local scmtype="none"
   if [ "$(is_scm_type .hg)" == "true" ]; then
      scmtype="mercurial"
   else
      if [ "$(is_scm_type .svn)" == "true" ]; then
         scmtype="subversion"
      else
        if [ "$(is_scm_type .git)" == "true" ]; then
            scmtype="git"
        fi
      fi
   fi
   echo $scmtype
}

function get_scm_info(){
   local scmType=$(getSCM)
   echo
   echo "[$scmType]"
   scm_${scmType}Info
}

function get_git_branch(){
   get_branch
}

function get_subversion_branch(){
   local aux=$(svn info|grep ^URL:|cut -d'/' -f4-|tr '/' '\n'|tail -2)
   echo $aux|sed s:" ":"/":g
}

function get_mercurial_branch(){
   hg branch
}

function get_none_branch(){
   echo develop
   }

function get_scm_branch(){
   get_$(getSCM)_branch
}


function versionFileError(){
   exitError "$1
Es necesario definir un $VERSION_FILE del siguiente estilo:
Project: webCalculator
Module: frontend
Version: 1.1
Organization: SoftwareSano
PrefixOrganization: ss" $2
}

function getVersionProperties(){
   pushd . >/dev/null
   # Find VERSION_FILE
   while [ ! -f "$VERSION_FILE" ] && [ ! "$(pwd)" = "/" ]; do cd ..; done
   if [ -f "$VERSION_FILE" ]; then
       PREFIX_PROJECT=`grep "^Project:" $VERSION_FILE|sed s:"^Project\:":"":g|awk ' {print $1} '`
       if [ "$PREFIX_PROJECT" == "" ]; then
          versionFileError "No se ha definido el nombre del proyecto" 1
       fi
       PREFIX_ORGANIZATION=`grep "^PrefixOrganization:" $VERSION_FILE|sed s:"^PrefixOrganization\:":"":g|awk ' {print $1} '`
       if [ "$PREFIX_ORGANIZATION" == "" ]; then
          versionFileError "No se ha definido la organización a la que pertenece este proyecto" 1
       fi
       MODULE_PROJECT=`grep "^Module:" $VERSION_FILE|sed s:"^Module\:":"":g|awk ' {print $1} '`
       if [ "$MODULE_PROJECT" == "" ]; then
          versionFileError "No se ha definido el nombre del módulo" 1
       fi
       VERSION_PROJECT=`grep "^Version:" $VERSION_FILE|sed s:"^Version\:":"":g|awk ' {print $1} '|sed s:"-SNAPSHOT":"":g`
       if [ "$VERSION_PROJECT" == "" ]; then
          versionFileError "No se ha definido la version del proyecto" 1
       fi
   fi
   popd >/dev/null
}

function mavenVersion(){
   VERSION_PROJECT=`grep "<version>" pom.xml|head -1|sed s:"</\?version>":"":g|awk ' {print $1} '|sed s:"-SNAPSHOT":"":g`
   echo $VERSION_PROJECT
}

function getVersionModule(){
   getVersionProperties
   if [ "$VERSION_PROJECT" != "" ]; then
      echo $VERSION_PROJECT
      return 0
   fi
   if [ "$(is_pdi_compliant)" == 1 ]; then
      VERSION_PROJECT=$(get_version)
   else
      if [ -f "pom.xml" ]; then
         VERSION_PROJECT=$(mavenVersion)
      else
         versionFileError " " 1
      fi
   fi
   echo $VERSION_PROJECT
}

# It returns "true" if its a stable branch
function is_stable_branch(){
    local branch="$(get_scm_branch_type)"
    case $branch in
        feature|bug|hotfix|task) echo "false";;
        release) echo "true";;
        +(+([[:digit:]])\.)+([[:digit:]]) ) echo "true" ;;
        develop) echo "true";;
        master) echo "true";;
        *) echo "false";;
    esac
}

function get_os_release(){
   if [ -f /etc/redhat-release ]; then
      echo "el$(sed s:".*release ":"":g /etc/redhat-release |cut -d'.' -f1)"
   else
      uname -rs|sed s:" ":"":g
   fi
}

function getReleaseModule(){
   echo $(get_scm_revision_$(getSCM)).$(get_os_release)
}

function getPrefixProject(){
   getVersionProperties
   #Trying with git
   if [[ "$PREFIX_PROJECT" == "" ]]; then
      PREFIX_PROJECT=$(git describe --tags --match */Project 2>/dev/null|sed s:"/.*":"":g 2>/dev/null)
      # If it's a maven project
      if [[ "$PREFIX_PROJECT" == "" ]]; then
         PREFIX_PROJECT=`grep "<artifactId>" pom.xml 2>/dev/null|head -1|sed s:"</\?artifactId>":"":g|awk ' {print $1} '`
      fi
   fi
   echo $PREFIX_PROJECT
}

function getPrefixOrganization(){
   getVersionProperties
   #Trying with git
   if [[ "$PREFIX_ORGANIZATION" == "" ]]; then
      PREFIX_ORGANIZATION=$(git describe --tags --match */PrefixOrganization 2>/dev/null|sed s:"/.*":"":g 2>/dev/null)
      # If it's a maven project
      if [[ "$PREFIX_ORGANIZATION" == "" ]]; then
       if [ "$(grep '<organization.acronym>' pom.xml 2>/dev/null)" != "" ]; then
         PREFIX_ORGANIZATION=`grep "<organization.acronym>" pom.xml|head -1|sed s:"</\?organization.acronym>":"":g|awk ' {print $1} '`
       fi
      fi
      [[ -z $PREFIX_ORGANIZATION ]] && PREFIX_ORGANIZATION="$DEFAULT_PREFIX_ORGANIZATION"
   fi
   echo $PREFIX_ORGANIZATION
}

function getProjectModule(){
   getVersionProperties
   echo $MODULE_PROJECT
}
