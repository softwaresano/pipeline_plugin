#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1


function absdir() {
    pushd $1 > /dev/null ; ABS_PATH=`pwd -P` ; popd > /dev/null ; echo $ABS_PATH
}

function log()   {

        echo "" >> $LOG
        echo "[package] $1" | tee -a $LOG
        echo "" >> $LOG
}

function warn()  {
        log "WARNING: $1"
}

function error() {
        log "ERROR: $1"
}

function fatal() {
        error $1
        error "check the packaging log at $LOG for more detailed error messages."
        echo "------------------------------------------------------------------------"
        tail $LOG
        echo "------------------------------------------------------------------------"
        exit 1
}

function processSpecs(){
   local specFile
   for specFile in SPECS/*.spec; do
       #Python setup.py --spec-only doesn´t add buildarch
       echo "" >$specFile.temp
       if [ -z "$(grep "^BuildArch:" $specFile)" ]; then
          echo "BuildArch:     $ARCH" >> $specFile.temp            
       fi
       if [ -z "$(grep "^License:" $specFile)" ]; then
          echo "License:     No license"   >> $specFile.temp   
       else
         # delete multiline License field
         lines=($(grep -n "^[A-Z].*: " $specFile | grep License -A 1 | cut -d ":" -f 1))
         L1=$((${lines[0]}+1))
         L2=$((${lines[1]}-1))
         if [[ $L2 -gt $L1 ]] ; then
            sed $specFile -i -e ${L1},${L2}d 
         fi
       fi
       cat $specFile >> $specFile.temp
       rm $specFile
       mv $specFile.temp $specFile

       #Define name package(organization-project-%name) 
       # and original name
       local nameComponent=$(grep "^%define name" $specFile |awk '{ print $3 }')
       sed -i s:"^%define name .*":"%define original_name $nameComponent":g $specFile
       sed -i s#"^Name: %{name}"#"Name: $nameComponent"#g $specFile
       sed -i s#"^BuildRoot:.*"#""#g $specFile
       sed -i s#"%prep"#"%prep\nmkdir -p \$RPM_BUILD_ROOT"#g $specFile
   done;
}

################################################################################
# Init variables with default values
################################################################################
function init(){ 
   HERE=$(absdir `dirname $0`)
   DIR=$(absdir `pwd`)
   DEF_REQS=requirements.txt
   REQS=
   DEF_REQS_LOCAL=requirements_local.txt
   REQS_LOCAL=

   OUT=

   DOWNS=/tmp/python-package-downs-$$
   CACHE=/tmp/python-package-cache

   PIP=pip-2.7
   PYTHON=python2.7

   ARCH="$(arch)"
   DEF_GIT_VERSION_SCRIPT=$DP_HOME/tools/versions/get_git_version_string.sh

   GIT_VERSION_SCRIPT=
   INCLUDE_DEPS=1

   ORGANIZATION="tdigital"
   RPM_GROUP="Applications/$ORGANIZATION"
   RPM_VENDOR="Telefonica I+D"
   RPM_PACKAGER="Telefonica I+D"
   RPM_EXTRA_DEPS=""
   RPM_PROVIDES_PREFIX="$ORGANIZATION-python2.7-"
   RPM_REL="1"
   RPM_REL_TAG="_$ORGANIZATION"
}

################################################################################
# command line arguments checks
################################################################################
function getParameters(){
   while [ "$1" ]
   do
       case $1 in
       --dir)
           DIR=$2
           shift
           ;;
       --reqs)
           REQS=$2
           shift
           ;;
       --reqs-local)
           REQS_LOCAL=$2
           shift
           ;;
       --out)
           OUT=$2
           shift
           ;;
       --no-include-deps)
           INCLUDE_DEPS=0
           ;;
       --cache)
           CACHE=$2
           shift
           ;;
       --downs)
           DOWNS=$2
           shift
           ;;
       --pip)
           PIP=$2
           shift
           ;;
       --git-version)
           GIT_VERSION_SCRIPT=$2
           shift
           ;;
       --group)
           RPM_GROUP=$2
           shift
           ;;
       --packager)
           RPM_PACKAGER=$2
           shift
           ;;
       --provides-prefix)
           RPM_PROVIDES_PREFIX=$2
           shift
           ;;
       --release)
          RPM_REL=$2
          shift
          ;;
       --release-tag)
          RPM_REL_TAG=$2
          shift
          ;;
       --extra-deps)
          RPM_EXTRA_DEPS=$2
          shift
          ;;
       --vendor)
          RPM_VENDOR=$2
          shift
          ;;
       --help)
          echo "Usage: $(basename $0) ARGS"
          echo "where ARGS can be:"
          cat << EOF
        
Basic:
    
  --dir DIR           top directory with a 'setup.py' and a 'requirements.txt' file (default: $DIR)
  --reqs FILE         requirements file name (default: $DEF_REQS)
  --reqs-local FILE   local requirements file name (default: $DEF_REQS_LOCAL)
  --downs DIR         temporal downloads directory (default: $DOWNS)
  --out DIR           directory for the output RPMs (default: $DIR/)
  --cache DIR         downloads cache directory (default: /tmp/python-package-cache)

RPM package parameters:

  --group GROUP       group name (default: $RPM_GROUP)    
  --vendor VENDOR     vendor (eg. "Jane Doe <jane@example.net>") (default: $RPM_VENDOR)
  --packager PACKAGER packager (eg. "Jane Doe <jane@example.net>") (default: $RPM_PACKAGER)
  --extra-deps        spaces/comma-separated list of extra dependencies (ie, "python = 2.7, redis apache >= 1.3")
  --provides-prefix   prefix for "provides" for dependencies (default: "$RPM_PROVIDES_PREFIX")
  --release NUMBER    release number for dependencies (default: "$RPM_REL")
  --release-tag TAG   release tag for dependencies (default: "$RPM_REL_TAG")

Advanced parameters:
    
  --pip EXE           pip executable (default: $PIP)    
  --python EXE        python executable (default: $PYTHON)    
  --arch ARCH         local architecture (default: $ARCH)    
  --git-version EXE   script for getting the git version (default: $DEF_GIT_VERSION_SCRIPT)
  --no-include-deps   do not download transitive dependencies

Some notes:

  * make sure the downloads directory can be cleaned up because ALL CONTENTS IN THIS DIR WILL BE REMOVED.
  * the downloads directory cannot be a NFS, SMB or Vagrant directory, as some operations (ie, hard links) will fail.
  
EOF
           exit 0
           ;;
       *)
           echo "!!! ERROR: unknown parameters. Run $(basename $0) --help for getting the command line args";;
       esac
       shift
   done

################################################################################
# command line arguments checks
################################################################################

   # get a full path to the requirements file
   if [ "x$REQS" = "x" ] ; then
       FULL_REQS=$DIR/$DEF_REQS
   else
       FULL_REQS=$REQS
   fi

   FULL_REQS=$(absdir `dirname $FULL_REQS`)/$(basename $FULL_REQS)
   if [ ! -f $FULL_REQS ] ; then
       log "ERROR: no requirements file found at $FULL_REQS"
       log "ERROR: Run $(basename $0) --help for getting the command line args"
       exit 0
   fi

   # get a full path to the local requirements file
   if [ "x$REQS_LOCAL" = "x" ] ; then
      FULL_REQS_LOCAL=$DIR/$DEF_REQS_LOCAL
   else
      FULL_REQS_LOCAL=$REQS_LOCAL
   fi
   FULL_REQS_LOCAL=$(absdir `dirname $FULL_REQS_LOCAL`)/$(basename $FULL_REQS_LOCAL)

   # check there is a setup.py at the work directory
   FULL_SETUP_PY=$DIR/setup.py
   if [ ! -f $FULL_SETUP_PY ] ; then
      log "ERROR: no 'setup.py' file found at $FULL_SETUP_PY"
      log "ERROR: Run $(basename $0) --help for getting the command line args"
      exit 0
   fi

   DIR=`absdir $DIR`

   if [ "x$OUT" = "x" ] ; then
      OUT=$DIR
   fi
   OUT=`absdir $OUT`

   # check the git version script
   if [ "x$GIT_VERSION_SCRIPT" = "x" ] ; then
      GIT_VERSION_SCRIPT=$DEF_GIT_VERSION_SCRIPT
   fi
   if [ ! -f $GIT_VERSION_SCRIPT ] ; then
      log "ERROR: no GIT version script found at $GIT_VERSION_SCRIPT"
      log "ERROR: Run $(basename $0) --help for getting the command line args"
      exit 0
   fi
   source $GIT_VERSION_SCRIPT

   if [ "x$ARCH" = "x" ] ; then
      log "ERROR: could not detect the local architecture"
      log "ERROR: Run $(basename $0) --help for getting the command line args"
      exit 0
   fi
}

#############################
# get version/release
#############################
function getVersion(){
   pushd $DIR > /dev/null

   GIT_VERSION=$(get_version 2>/dev/null)
   GIT_REVISION=$(get_revision 2>/dev/null)

   if [ "x$GIT_VERSION" = "x" ] ; then
       warn "using default version number !!"
       GIT_VERSION=$(git log --oneline | wc -l | awk '{ print $1 }')
   fi
   if [ "x$GIT_REVISION" = "x" ] ; then
      warn "using default release number !!"
      GIT_REVISION=1
   fi
   popd > /dev/null
}

#############################################
# Print a header with packaging parameters
#############################################
function header(){
   OUT=`absdir $OUT`
   LOG=$OUT/packaging.log
   
   [ -d $OUT ] || mkdir -p $OUT

   rm -f $LOG
   touch $LOG

   log "Packaging:"
   log "... requirements:         $FULL_REQS"
   log "..... transitive deps:    $INCLUDE_DEPS (0=no, 1=yes)"
   log "... requirements (local): $FULL_REQS_LOCAL"
   log "... work directory:       $DIR"
   log "... output RPMs dir:      $OUT"
   log "... downloads dir:        $DOWNS"
   log "... architecture:         $ARCH"
   log "... version - release:    $GIT_VERSION - $GIT_REVISION"
   log "... packaging log:        $LOG"
}
###########################
# Generates rpmName from local resource, adding $ORGANIZATION-
################################
function generateRpmName(){
   local currentName=$1
   local rpmName
   local newName
   rpmName=$(echo $currentName|sed s:"_":"-":g)
   echo ${ORGANIZATION}-$rpmName
}

#############################
# process the local reqs
#############################
function processLocalReq(){
   REQUIRES_LOCAL=""
   if [ -f $FULL_REQS_LOCAL ] ; then
      LOCAL_REQS_DIR=$DOWNS/local_reqs
      log "Creating temporal directory for local dependencies at $LOCAL_REQS_DIR..."

       rm -rf $LOCAL_REQS_DIR
       mkdir -p $LOCAL_REQS_DIR


       cd $DIR && $PIP install -t $LOCAL_REQS_DIR --no-deps -r $FULL_REQS_LOCAL
       if [ $? -ne 0 ] ; then
          fatal "failed to download requirements..."
       fi
    
       for INFO in $LOCAL_REQS_DIR/*.egg-info/PKG-INFO ; do
          if [ -f $INFO ] ; then
             NAME=$(grep -e '^Name:' $INFO | awk '{ print $2 }' | sed -e 's/-/_/g')

             log "... detected dependency to \"$NAME\""
             NAME=$(generateRpmName "$NAME")
             REQUIRES_LOCAL="$NAME $REQUIRES_LOCAL"
           fi
       done
       log "Computed local package dependencies: \"$REQUIRES_LOCAL\""
    
       log "... cleaning up temporal directory"
       rm -rf $LOCAL_REQS_DIR
   else
       warn "no local requirements file found at $FULL_REQS_LOCAL"
   fi
}

#############################
# download stuff
#############################
function downloadExternalDependencies(){
   log "Downloading external dependencies"

   PIP_BASE_ARGS="--ignore-installed --no-install --timeout 120"
   if [ $INCLUDE_DEPS -eq 0 ] ; then
      PIP_BASE_ARGS="$PIP_BASE_ARGS --no-deps"
   else
      log "... including transitive dependencies"
   fi

   $PIP install $PIP_BASE_ARGS --download-cache $CACHE --download $DOWNS -r $FULL_REQS
   if [ $? -ne 0 ] ; then
      fatal "failed to download requirements..."
   fi

   #### uncompress everything

   log "Uncompressing packages"
   CNT=1
   cd $DOWNS
   for P in $DOWNS/*.tar.gz $DOWNS/*.tgz $DOWNS/*.zip; do
      #Workaround for github dependencies(change_dir)
      local change_dir="" 
      
      if [ -f $P ] ; then
         log "... [$CNT] uncompressing $P..."
         if [[ $P =~ \.zip$ ]]; then
            unzip -xU $P    2>>$LOG >>$LOG
         else
            tar -xvpf $P    2>>$LOG >>$LOG
         fi
         if [ $? -ne 0 ] ; then
            fatal "uncompressing $P..."
         fi
         #Regenerating dependency sources
         componentName=$(echo basename $P)
         local suffix_file=""
         if [[ "$componentName" = *.zip ]]; then
            suffix_file="zip"
         else
            if [[ "$componentName" = *.tgz ]]; then
               suffix_file="tgz"
            else 
               if [[ "$componentName" = *.tar.gz ]]; then
               suffix_file="tar.gz"
               fi
            fi
         fi
         componentName=$(echo $(basename $P)|sed s:"\.${suffix_file}$":"":g)
         mkdir -p $componentName/dist/SOURCES
         mv $P $componentName/dist/SOURCES
         pushd . >/dev/null
         cd $componentName/dist/SOURCES
         if [[ $P =~ \.zip$ ]]; then
            unzip -xU ${componentName}.zip    2>>$LOG >>$LOG
         else 
            tar -xvpf $(basename $P)          2>>$LOG >>$LOG
         fi
         if [ $? -ne 0 ] ; then
            fatal "uncompressing $P..."
         fi
         pushd . >/dev/null
         #Workaround for dependencies with github url
         cd $(dirname $(find . -name "setup.py"|tail -1))
         local component_version=$($PYTHON setup.py --version|tail -1)
         local component_name=$($PYTHON setup.py --name|tail -1)
         if [[ "${component_name}-${component_version}" != "$componentName" ]]; then
            local dirComponent=$(basename $PWD)
            cd ..
            componentName=${component_name}-${component_version}
            mv $dirComponent $componentName
            change_dir=${component_name}-${component_version}
         fi
         popd >/dev/null
         mv $componentName $RPM_PROVIDES_PREFIX${componentName}
         tar cvfz $RPM_PROVIDES_PREFIX${componentName}.tar.gz $RPM_PROVIDES_PREFIX$componentName
         rm -Rf ${componentName}.*
         if [[ "$change_dir" != "" ]]; then
            local old_dir=$(echo $PWD|sed s:"${DOWNS}/":"":g|cut -d'/' -f1)
            warn "Rename $old_dir for $change_dir"
            cp -R $RPM_PROVIDES_PREFIX$componentName/* $DOWNS/$old_dir
            mv $DOWNS/$old_dir $DOWNS/$change_dir
         fi
         popd >/dev/null
         CNT=$(($CNT + 1))
      fi
   done
}
#############################
# build RPMs
#############################

function buildRpms(){
   REQUIRES=""

   log "Building RPMs..."
   CNT=1
   for PACKAGE_DIR in $DOWNS/* ; do
      SETUP_PY=$PACKAGE_DIR/setup.py
      if [ -f $SETUP_PY ] ; then
         cd $PACKAGE_DIR
            
         log "... [$CNT] obtaining package info on $PACKAGE_DIR"
         cd $PACKAGE_DIR && $PYTHON $SETUP_PY egg_info --quiet    >/dev/null 2>/dev/null
         if [ $? -ne 0 ] ; then
            warn "...... didnt like egg_info: obtaining info by setup.py"
            PACKAGE_VERSION=$($PYTHON setup.py --version)
            PACKAGE=$($PYTHON setup.py --name)
            if [[ "$PACKAGE" == "" || "$PACKAGE_VERSION" == "" ]]; then
               warn "...... didnt like setup.py: obtaining info by parsing directory name"
               B=${PACKAGE_DIR##*/}
               PACKAGE_VERSION=${B##*-}
               PACKAGE=${B%-*}
            fi
         else
            # search for the first PKG-INFO returned by find
            INFO_FILE=$(find -name 'PKG-INFO'| head -1)
            log "... [$CNT] using info from $INFO_FILE"
            if [ ! -f $INFO_FILE ] ; then
               fatal "getting info file for $PACKAGE_DIR..."
            fi

            PACKAGE=$(grep -e '^Name:' $INFO_FILE | awk '{ print $2 }' | sed -e 's/_/-/g')
            if [ $? -ne 0 ] ; then
               fatal "obtaining package name on $PACKAGE_DIR..."
            fi

            PACKAGE_VERSION=$(grep -e '^Version:' $INFO_FILE | awk '{ print $2 }')
            #Workaround rpmbuild. (Rpm version doesn´t support -)
            NEW_PACKAGE_VERSION=$(echo $PACKAGE_VERSION|sed s:"-":"_":g)
            PACKAGE_VERSION=$NEW_PACKAGE_VERSION
            if [ $? -ne 0 ] ; then
               fatal "obtaining package version on $PACKAGE_DIR..."
            fi
         fi

         FULL_PACKAGE=$RPM_PROVIDES_PREFIX$PACKAGE
         FULL_PACKAGE_REL=$RPM_REL$RPM_REL_TAG
         FULL_PACKAGE_VERSION=$PACKAGE_VERSION-$FULL_PACKAGE_REL

         log "... [$CNT] building RPM for $PACKAGE ($FULL_PACKAGE == $FULL_PACKAGE_VERSION)"
    
         # remove the provided 'setup.cfg' (if it exists), because packagers sometimes
         # include some annoying 'depends='
         SETUP_CFG=$PACKAGE_DIR/setup.cfg
         log "...... overwriting $SETUP_CFG"
         echo "[bdist_rpm]"                                        > $SETUP_CFG
         echo "vendor   = $RPM_VENDOR"                            >> $SETUP_CFG
         echo "packager = $RPM_PACKAGER"                          >> $SETUP_CFG
         echo "release  = $FULL_PACKAGE_REL"                      >> $SETUP_CFG
        
         $PYTHON $SETUP_PY bdist_rpm --spec-only --python $PYTHON  2>>$LOG >>$LOG
         if [ $? -ne 0 ] ; then
            fatal "failed to create RPM from $PACKAGE..."
         fi
         pushd . >/dev/null
         mkdir dist/SPECS
         mv dist/*.spec dist/SPECS
         cd dist
         processSpecs
         $DP_HOME/profiles/package/redhat/dp_package.sh \
           --version $PACKAGE_VERSION \
           --release $FULL_PACKAGE_REL \
           --organization $ORGANIZATION \
           --project python \
           --debug
         if [ $? -ne 0 ]; then
            fatal "failed to create RPM from $PACKAGE..."
         fi
         popd >/dev/null
         REQUIRES="$REQUIRES  $FULL_PACKAGE = $FULL_PACKAGE_VERSION"
         CNT=$(($CNT + 1))
      fi
   done
}


################################################################################
# main
################################################################################
init $*
getParameters $*
getVersion
header

#############################
# prepare stuff
#############################

log "Cleaning any previous RPMs at $OUT..."
rm -f $OUT/*.rpm

log "Creating temporal downloads directory $DOWNS..."
rm -rf $DOWNS
mkdir -p $DOWNS

processLocalReq
downloadExternalDependencies
buildRpms


#############################
# calculate dependencies
#############################

log "Summarizing dependencies..."
[ "$RPM_EXTRA_DEPS" != "x" ] && REQUIRES="$REQUIRES $RPM_EXTRA_DEPS"
[ "$REQUIRES_LOCAL" != "x" ] && REQUIRES="$REQUIRES $REQUIRES_LOCAL"

echo $REQUIRES > $OUT/rpm_requires.txt
log "... computed package requirements: $REQUIRES"

log "Cleaning up..."
rm -rf $DOWNS

log "Success!!"
log "Bye!!"
