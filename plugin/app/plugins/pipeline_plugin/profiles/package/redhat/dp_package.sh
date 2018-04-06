#!/bin/bash
if [[ -z "$DP_HOME" ]]; then
   DP_HOME=$(dirname $(readlink -f $(which dp_package.sh 2>/dev/null) 2>/dev/null) 2>/dev/null)
   [[ -z "$DP_HOME" ]] && echo "[ERROR] DP_HOME must be defined" && exit 1
fi
### HELP section
dp_help_message="This command has not any help
[redhat] package type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE

source $DP_HOME/tools/repo/dp_publishArtifactInOtherRepo.sh
source $DP_HOME/tools/versions/dp_version.sh
source $DP_HOME/profiles/publish/rpm/dp_publish.sh


function currentDir(){
   DIR=$DP_HOME
}

currentDir
source $DP_HOME/phases/build/projectType.sh build

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

function help(){
   _message "
 Generate a rpm from a .spec file.
 Usage: $(basename $0) [ARGS]
        where ARGS can be:
        
Basic:

  --version      VERSION      rpm version
  --release      RELEASE      rpm release
  --help         This 

Advanced parameters:

  --organization ORGANIZATION Name company. The rpm name includes organization(Ex: pdi-)
  --project  

Debug parameters
  --debug: Enable debug options.

Some notes:
  Without parameters, this script calculates the version and release from scm info.

Ex:
   $0 --help
   $0
   $0 --debug --version 1.0 --release 2
   $0 --debug --version 1.0 --release 2  --organization pdi --project develenv
"
}

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

function helpError(){
   packageError "$1"
   help
   exitPackage "$2"
}

function exitError(){
   packageError "$1"
   exitPackage "$2"
}

function createChangeLog(){
   #Si no existe el changelog se genera a partir de los logs del SCM
   if [ "`cat $modifiedSpecFile|egrep \"^%changelog\"`" == "" ]; then
      if [ "$scmtype" == "git" ]; then
         echo "%changelog" >> $modifiedSpecFile
         git log --format="%ad - %aE %h %s"|grep "Merge branch 'develop'"|awk '{print "* "$1" "$2" "$3" "$5" - "$8" - "$9"\n  - "$16}' >> $modifiedSpecFile
      fi
   fi
}

function checkSpecFile(){
   #Tests the mandatory sections and tags
   local tags="License: Vendor: Summary: %description BuildArch:"
   local tag
   for tag in $tags; do
      if [ $(cat $1|grep \"^${tag}\"|wc -l) -gt 0 ]; then
         exitError "[$1] No tiene definido el tag [$tag]" 1
      fi
   done;
}
# Is posible add <prefix-organization>-<project-name> to package?
function is_modificable(){
   local field=$1
   local spec_file=$2
   egrep "^( |\t)*%define( |\t)*modify_${field}( |\t)*false( |\t)*$" $spec_file
   if [ $? == 0 ]; then
      echo "false"
   else
      echo "true"
   fi
}

# If is defined in .spec %define rpm_name_modify false
function is_specfile_modificable(){
   egrep "^( |\t)*%define( |\t)*modify_specfile( |\t)*false( |\t)*$" $1
   if [ $? == 0 ]; then
      echo "false"
   else
      echo "true"
   fi
}



function changeSection(){
   sections="$1"
   substitute="$2"
   filtered=`echo $substitute|sed s/:/\\\\\\\:/g`
   for section in $sections; do
      # Extract sections in spec file
      line=$(expr `egrep -n "^%prep[ |\t]*$|^%install[ |\t]*$|^%build[ |\t]*$|^%description[ |\t]*$|^%files[ |\t]*$|^%doc[ |\t]*$|^%clean[ |\t]*$|^%changelog[ |\t]*$|^%pre[ |\t]*$|^%post[ |\t]*$|^%preun[ |\t]*$|^%postun[ |\t]*$" $modifiedSpecFile|grep -n "%${section}$"|cut -d':' -f1` + 1)
      if [ "$line" -gt 1 ]; then
         nextSection=`cat $auxTmpFile|head -n $line|tail -n 1|cut -d':' -f2`
         if [ "$substitute" != "scm.info" ]; then
            # Add filtered at the final rpm section
            sed  -i s:"^${nextSection}[ |\t]*$":"$filtered\\n${nextSection}":g $modifiedSpecFile
         else
            echo "#!/bin/bash" > deleteme.spec.sh
            echo 'f2="$(<scm.info)"' >> deleteme.spec.sh
            echo "awk -vf2=\"\$f2\" '/^${nextSection}/{print f2;print;next}1' $modifiedSpecFile> deleteme.spec"  >> deleteme.spec.sh
            echo "mv deleteme.spec $modifiedSpecFile "  >> deleteme.spec.sh
            chmod 755 deleteme.spec.sh
            ./deleteme.spec.sh
            rm -Rf deleteme.spec.sh
          fi
      fi
   done;
}

function insert_scm_info(){
   get_scm_info > scm.info
   changeSection "description" "scm.info"
   rm -Rf scm.info
}

function changeSections(){
   #exclude Defaults Files
   auxTmpFile="new.spec.tmp"
   egrep -n "^%prep[ |\t]*$|^%install[ |\t]*$|^%build[ |\t]*$|^%description[ |\t]*$|^%files[ |\t]*$|^%doc[ |\t]*$|^%clean[ |\t]*$|^%changelog[ |\t]*$|^%pre[ |\t]*$|^%post[ |\t]*$|^%preun[ |\t]*$|^%postun[ |\t]*$" $modifiedSpecFile >$auxTmpFile
   changeSection "install build prep" "%_default_exclude_files"
   changeSection "description" "----------------------------------Builder---------------------------------------"
   changeSection "description" "Hostname: $(uname -n)"
   changeSection "description" "SO release: $(cat /etc/redhat-release)"
   changeSection "description" "SO version: $(cat /proc/version)"
   if ! [ -z "$BUILD_ID" ]; then
      changeSection "description" "----------------------------------Jenkins---------------------------------------"
      changeSection "description" "Build ID: $BUILD_ID"
      changeSection "description" "Build URL: $BUILD_URL"
      changeSection "description" "----------------------------------Develenv--------------------------------------"
      changeSection "description" "Version: $PROJECT_VERSION"
   fi
   changeSection "description" "----------------------------------rpmBuild--------------------------------------"
   changeSection "description"  "$rpmBuildCommand"
   changeSection "description" "-------------------------------------SCM----------------------------------------"
   insert_scm_info
   rm -Rf $auxTmpFile
}

function filterSpecFile(){
   if [ "$(is_modificable package_name $specFile)" == "true" ]; then
      if [[ "$PREFIX_PROJECT" != "" ]]; then
        sed s:"^Name\:.*":"Name\: $packageName\\n%define _project_name $PREFIX_PROJECT":g $specFile >>$modifiedSpecFile
        sed -i  s:"^%define project_user.*":"%define project_user $PREFIX_ORGANIZATION-$PREFIX_PROJECT":g $modifiedSpecFile
        sed -i  s:"^%define [ ]* _prefix_ .*":"%define _prefix_ /opt/$PREFIX_ORGANIZATION/$PREFIX_PROJECT/$PROJECT_MODULE":g $modifiedSpecFile
      fi
   else
      sed s:"^Name\:.*":"Name\: $packageName":g $specFile >>$modifiedSpecFile
      sed -i  s:"^%define _prefix_.*":"%define _prefix_ /opt":g $modifiedSpecFile
   fi
   if [ "`cat $modifiedSpecFile|grep \"^BuildRoot:\"`" == "" ]; then
      #Si no está definido el buildRoot se introduce (Workaround para Redhat 5)
      sed -i s:"^BuildArch\:":"BuildRoot\: %{_topdir}/BUILDROOT\\nBuildArch\:":g $modifiedSpecFile
   fi
   createChangeLog
   phases="prep build install clean pre post preun postun"
   for phase in $phases; do
      sed -i  s:"^%$phase\( \|\t\)*":"%${phase}":g $modifiedSpecFile
      sed -i  s:"^%$phase\$":"%$phase\\n%{_log_${phase}_init}":g $modifiedSpecFile
   done;
   changeSections
}

function testParameters(){
   while [ "$1" ]
   do
      case $1 in
         --version)
           versionModule=$2
           shift
         ;;
         --release)
           releaseModule=$2
         shift
         ;;
         --organization)
           PREFIX_ORGANIZATION=$2
           shift
         ;;
         --project)
           PREFIX_PROJECT=$2
           shift
         ;;
         --debug)
           debug=true
         ;;
         --help)
           help
           exit 0
         ;;
         *)
           echo "!!! ERROR: unknown parameters. Run $(basename $0) --help for getting the command line args"
           exit 1
         ;;
      esac
      shift
   done

   if [ -z "$versionModule" ]; then
      versionModule=$(getVersionModule)
      if [ $? -ne 0 ]; then
         echo $versionModule
         exit 1
      fi
   fi
   if [ -z "$releaseModule" ]; then 
      releaseModule=$(getReleaseModule)
      if [ $? -ne 0 ]; then
         echo $releaseModule
         exit 1
      fi
   fi
   if [ -z "$PREFIX_PROJECT" ]; then
      PREFIX_PROJECT=$(getPrefixProject)

   fi
   if [ -z "$PREFIX_ORGANIZATION" ]; then
      PREFIX_ORGANIZATION=$(getPrefixOrganization)

   fi
   if [ -z "$PROJECT_MODULE" ]; then
      PROJECT_MODULE=$(getProjectModule)
   fi
}

function addRPMDirs(){
    local specFile=$1
    RPM_HOME=$TARGET_DIR/rpm/RPMS
    mkdir -p $RPM_HOME
    # Fijamos que los SOURCES de los RPMS estén a la misma altura
    SOURCES_RPM_DIR=$(dirname $(dirname $specFile))
    echo -e "\n\
%define _buildshell /bin/bash
%define _topdir ${TOPDIR}
%define _debug_dir_build ${debug_dir}\n\
%define _builddir %{_topdir}/BUILD\n\
%define _rpmdir $RPM_HOME\n\
%define _sourcedir %{_topdir}/../../../${SOURCES_RPM_DIR}/SOURCES\n\
%define _specdir `dirname $modifiedSpecFile`\n\
%define _srcrpmdir %{_topdir}/../../../src\n\
%define pipeline_plugin_version `cat $DP_HOME/$VERSION_FILE|grep 'Version:'|awk '{ print $2 }'`" >$modifiedSpecFile
}

function getRpmName(){
   local specFile=$1
   local versionModule=$2
   local releaseModule=$3
   local parameters=$(cat $specFile |egrep "^Version:|^Release:|^BuildArch:|^Name:"\
                     |sort|awk '{print $2}')
   
   local version=$(echo $parameters|awk '{print $4}')
   version=${version/\%{versionModule\}/$versionModule}
   
   # Si la version está en el .spec
   [[ $(echo $version|egrep -v "%{.*}") ]] && versionModule=$version
   local release=$(echo $parameters|awk '{print $3}')
   release=${release/\%{os_release\}/$(dp_os_release.sh)}
   # Si la release está en el .spec
   [[ $(echo $release|egrep -v "%{.*}") ]] && releaseModule=$release
   local buildArch=$(echo $parameters|awk '{print $1}')
   local name=$(echo $parameters|awk '{print $2}')
   echo $name-$versionModule-$releaseModule.$buildArch.rpm
}


function createRPM(){
   specFile=$1
   rpmGeneratedName=""
   _log "Creating rpm $specFile"
   checkSpecFile $specFile
   modificable_package_name=$(is_modificable package_name $specFile)
   packageName=`cat $specFile |egrep "^Name:"|awk {'print $2'}`
   local architecture=`cat $specFile |grep "^BuildArch:"|awk '{print $2}'`
   local fullName=$(getRpmName $specFile $versionModule $releaseModule)
   if ! [ -z $PREFIX_PROJECT ]; then
       if [ "$modificable_package_name" == "true" ]; then
          packageName=${PREFIX_ORGANIZATION}-${PREFIX_PROJECT}-$packageName
          fullName=${PREFIX_ORGANIZATION}-${PREFIX_PROJECT}-$fullName
       fi
   fi
   rpm_name=${fullName/\.$architecture\.rpm}
   debug_dir=$debug_dir_base/${rpm_name}
   rm -Rf $debug_dir
   if [ "$?" != 0 ]; then
      exitError "No existen permisos de escritura en el directorio $debug_dir"
      exit 1
   fi
   mkdir -p $debug_dir
   if [ $? != 0 ]; then
      exitError "No se puede crear el directorio $debug_dir. Puede que pertenezca a otro usuario" 1
   fi
   rm -Rf ${debug_dir}
   mkdir -p ${debug_dir}
   modifiedSpecFile=${debug_dir}/$packageName.spec.mod
   #Adding rpm_macros
   addRPMDirs $specFile
   #Test if rpm exists
   [[ "$(is_new_artifact)" == "true" ]] && \
       _log "[WARNING] $(get_repo_dir $fullName)/$fullName already exits. Remove this rpm if you want regenerate it" \
       && return 1;
   sed 1,${lineSeparator}d $packagerFile >> $modifiedSpecFile
   echo "" >> $modifiedSpecFile
   echo "## Original spec file" >> $modifiedSpecFile
   rpmBuildCommand="rpmbuild -v --clean --define 'os_release '$(dp_os_release.sh) --define 'versionModule '$versionModule \
--define 'releaseModule '$releaseModule $prePackageExtension -bb $modifiedSpecFile"
   if [ "$(is_modificable spec_file $specFile)" == "true" ]; then
      filterSpecFile $specFile
   else
      cat $specFile >>$modifiedSpecFile
   fi
   rm -Rf $TOPDIR
   mkdir -p $TOPDIR/BUILD
   _message "$rpmBuildCommand"
   echo "$rpmBuildCommand 2>$debug_dir/rpmbuild.error.log |\
              tee -a $debug_dir/rpmbuild.log  &&\
              exit \${PIPESTATUS[0]}" >$debug_dir/rpmbuild.sh
      echo "
errorCode=\$?
echo rpmbuildExit [\$errorCode]
exit \$errorCode
" >>$debug_dir/rpmbuild.sh
   chmod u+x $debug_dir/rpmbuild.sh
   $debug_dir/rpmbuild.sh
   errorCode=$?
   if [ "$errorCode" != "0" ]; then
      cat $debug_dir/rpmbuild.error.log
      exitError "Error[$errorCode] en la generación de rpm a partir del fichero $specFile \n\
Puedes consultar los logs en el directorio $debug_dir" $errorCode
   else 
      _log "[SUCCESS] rpmbuild [$specFile]"
   fi
   rm -Rf $SOURCE_DIR/.error
   rpmGeneratedName=$(grep ^Wrote: $debug_dir/rpmbuild.log|grep "\.rpm$"|awk '{print $2}')
   if [ "$?" == "0" ]; then
      _message "[INFO] Rpm content: $rpmGeneratedName"
      _message "-------------------------------------------------------------------"
       rpm -qlp $rpmGeneratedName
      _message "-------------------------------------------------------------------"
   fi
}

function init(){
   LANG=C
   DEFAULT_PREFIX_ORGANIZATION="NA"
   typeBuildProject=$(get_phase_TypeProject)
   scmtype=$(getSCM)
   testParameters $*
   currentDir
   SOURCE_DIR=$PWD
   packagerFile="$DP_HOME/profiles/package/redhat/dp_package.sh"
   lineSeparator=`grep -n "#### RPM MACROS ####" $packagerFile|grep -v "grep" |cut -d':' -f1`
}

function buildRPMS(){
   TARGET_DIR=${SOURCE_DIR}/target
   debug_dir_base=${TARGET_DIR}/.dp_rpm
   generated_rpms=$debug_dir_base/generated_rpms
   rm -Rf $debug_dir_base
   mkdir -p $debug_dir_base
   TOPDIR=${debug_dir_base}/topdir
   rm -Rf $TOPDIR
   mkdir -p $TOPDIR
   # Genera un rpm por cada fichero de *.spec
   for specFile in `find "." -name "*.spec"|grep -v target|sort`;do
      createRPM "$specFile"
      if [ "$?" == "0" ]; then
         echo $rpmGeneratedName >>$generated_rpms
         publishInOtherRepo $rpmGeneratedName
         if [ "$debug" == "true" ]; then
            _message "Logs de construcción de ${rpm_name}.${architecture}.rpm en $debug_dir"
         else
            rm -Rf $debug_dir
         fi
      fi
   done;
   if [ "$specFile" == "" ]; then
      exitError "No existe ningún fichero .spec" 1
   fi
}

function dp_prePackage() {
   prePackageExtension=""
   [ $(type prePackage 2>/dev/null|head -1 |wc -l) == 1 ] && _message "[INFO] PrePackage" && prePackage
}

function dp_postPackage() {
   [ $(type postPackage 2>/dev/null|head -1 |wc -l) == 1 ] && _message "[INFO] PostPackage" && postPackage
}

function checkIntegrity(){
   if [ "`echo $packagerFile|grep '^\./.*'`" != "" ]; then
      # Comprobamos si se trata del packager del pipeline o de una copiado.
      _log "[WARNING] Este script [$packagerFile] ha sido modificado a partir del script packager.sh del deployment pipeline."
      return;
   fi
   currentChecksum=$(cat $packagerFile |grep '^####Checksum:'|cut -d':' -f2)
   #head -n$(expr `cat dp_package.sh |grep -n '^####Checksum:'|cut -d ':' -f1` - 1) dp_package.sh|md5sum|awk '{print $1}'
   calculatedChecksum=$(head -n$(expr `cat $packagerFile |grep -n '^####Checksum:'|cut -d ':' -f1` - 1) $packagerFile|md5sum|awk '{print $1}')
   if [ "$currentChecksum" != "$calculatedChecksum" ]; then
      exitError "No se puede ejecutar [$packagerFile] porque existen modificaciones locales que no han sido entregadas en un repositorio.\n Copia [$packagerFile] en el repositorio de tu proyecto con el nombre package.sh" 1
   fi
}

# Execute and action after rpm is published
function post_publish(){
   if [ "$POST_PUBLISH_RPM_SCRIPT" != "" ]; then
      _log "[INFO] Execution [$POST_PUBLISH_RPM_SCRIPT] post publish rpm script"
      eval $POST_PUBLISH_RPM_SCRIPT $*
   fi
}

function execute(){
   init $*
   #checkIntegrity
   dp_prePackage
   buildRPMS
   dp_postPackage
   if [[ -f $generated_rpms ]]; then
      publish_rpms $generated_rpms && publish_3party_rpm_dependencies && post_publish $*
   else
      _log "[WARNING] Any new rpm has been created"
   fi
}

function main(){
   [ "$(basename $0)" == "dp_package.sh" ] && execute $* && exit $?
}
currentDir
VERSION_FILE="VERSION.txt"
if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   main --debug $*
else
   main $*
fi
exit $?
#### RPM MACROS ####
%define _do_check ERROR_VALUE=`echo $?`;if [ $ERROR_VALUE != "0" ]; then exit -1;fi
%define _rpm_name %{name}-%{version}-%{release}
%define _debug_dir /var/tmp/rpm/%{_rpm_name}
# START: MACROS DE LOGS
%define _default_log_color_pre \\033[47m\\033[1;34m
%define _default_log_color_suffix \\033[0m\\\\n
%define _error_color \\033[47m\\033[1;31m
%define _log _message(){\
   [[ "\$1" =~ "[ERROR]" ]] && messageColor="%{_error_color}" || messageColor="%{_default_log_color_pre}"\
   echo -en "${messageColor}\$1%{_default_log_color_suffix}\n"\
}\
_log(){\
   _message "[`date '+%Y-%m-%d %X'`] \$1"\
}
%define _log_init_build %{_log}\
_log "==== Init ====[env -->%{_debug_dir}/env_${logPhase}] [script --> %{_debug_dir}/${logPhase}]"\
%{__mkdir_p} %{_debug_dir_build}\
env >%{_debug_dir_build}/env_${logPhase}\
%{__cp} $0 %{_debug_dir_build}/${logPhase}
%define _log_init %{_log}\
_log "==== Init ====[env -->%{_debug_dir}/env_${logPhase}] [script --> %{_debug_dir}/${logPhase}]"\
%{__mkdir_p} %{_debug_dir}\
env >%{_debug_dir}/env_${logPhase}\
%{__cp} $0 %{_debug_dir}/${logPhase}
%define _log_prep logPhase="PREP"
%define _log_prep_init %{_log_prep}\
%{_log_init_build}
%define _log_clean logPhase="CLEAN"
%define _log_clean_init %{_log_clean}\
%{_log_init_build}
%define _log_build logPhase="BUILD"
%define _log_build_init %{_log_build}\
%{_log_init_build}
%define _log_install logPhase="INSTALL"
%define _log_install_init %{_log_install}\
%{_log_init_build}
%define _log_pre logPhase="PRE-INSTALL"
%define _log_pre_init %{_log_pre}\
%{_log_init}
%define _log_post logPhase="POST-INSTALL"
%define _log_post_init %{_log_post}\
%{_log_init}
%define _log_preun logPhase="PRE-UNINSTALL"
%define _log_preun_init %{_log_preun}\
%{_log_init}
%define _log_postun logPhase="POST-UNINSTALL"
%define _log_postun_init %{_log_postun}\
%{_log_init}
# END: MACROS DE LOGS

%define _default_exclude_files \
cd $RPM_BUILD_ROOT\
[ $? != 0 ] && exit 2 \
exludeFiles=".svn .svnignore .cvs .cvsignore .hg .hgignore .git .gitignore .classpath .settings .project *.bak *.*~"\
for excludeFile in $exludeFiles; do\
   rm -rf `find . -name "$excludeFile"`\
done;\
cd -

####Checksum:26dd25fb4f24a9df21504df87c005a82