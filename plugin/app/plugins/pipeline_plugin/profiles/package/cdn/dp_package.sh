#!/bin/bash

[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1

source "${DP_HOME:?}"/tools/versions/git.sh

### HELP section
dp_help_message="This command has not any help
[cdn] package type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

source $DP_HOME/dp_setEnv.sh
source $DP_HOME/profiles/package/redhat/createrepo.sh


if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
## Move generated rpms to RPM_REPO
function moveRpmRepo(){
   #Only if it's executed by develenv
   if [ "$(id -un)" == "develenv" ]; then
      rpm_home_repos="/home/develenv/app/repositories/rpms"
      if [ -d "$rpm_home_repos" ]; then
         for rpm_file in $(find . -name "*.rpm"); do
             rpm_arch=$(rpm -qp --queryformat "[%{ARCH}]" $rpm_file)
             rpm_arch_home_repos=$rpm_home_repos/$rpm_arch
             mkdir -p $rpm_arch_home_repos
             cp $rpm_file $rpm_arch_home_repos
         done;
         createrepo $rpm_arch_home_repos
      fi
   fi
}

function execute(){
   set -e # Returns error if any command returns error

   VERSION=`cat VERSION`
   RELEASE="b`git log --pretty=oneline | wc -l`"
   echo "Generating cdn-content-publisher RPM for version $VERSION-$RELEASE"

   # clean testing environment
   make distclean

   # generate distribution tarball
   make sdist

   mkdir -p ~/rpmbuild/SOURCES

   cp dist/*-$VERSION.tar.gz ~/rpmbuild/SOURCES

   # generate RPM package
   make rpm VERSION=$VERSION RELEASE=$RELEASE

   # move rpms to rpm_repos
   moveRpmRepo
}


execute
