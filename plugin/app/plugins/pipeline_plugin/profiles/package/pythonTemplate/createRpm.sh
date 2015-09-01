#!/bin/bash
######
# Generate a rpm with a python templates
#
####
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1


function createRpm(){
   ###
   # PARAMETERS
   ### 
   local templateFile="$1"
   local componentSources="$2"
   local outputDir="$3"
   local package="$4"
   local version="$5"
   local release="$6"
   local username="$7"
   local prefix="$9"
   local organization="$8"
   local requires="${10}"
   local DIR=$(dirname $(readlink -f $0))
   ###
   # CONSTANTS DEFINITION
   ###
   local pythondir=/usr
   local pythonSiteDir=/usr/lib/python2.7/site-packages
   local pythonbin=$pythondir/bin/python2.7 
   local rpmdir=$PWD/../target/$package/rpms/
   local specdir=$rpmdir/SPECS
   local sourcedir=$rpmdir/SOURCES
   rm -Rf $rpmdir && mkdir -p $sourcedir $specdir
   echo "
%define python_dir $pythondir
%define python_site_dir $pythonSiteDir
%define python_bin $pythonbin
%define template_name $package
%define component_sources $componentSources
%define template_output_dir $outputDir
%define template_version $version
%define template_release $release
%define template_username $username
%define template_requires $requires
Name:       $package
Version:    $version
Release:    $release
" >$specdir/$package.spec
   #Add template 
   cat $DIR/$templateFile >> $specdir/$package.spec
   pushd . >/dev/null
   #If exists el directory config
   cd ..
   if [ -d config ]; then
      find config -type f -exec \
         echo "%config(noreplace) %{template_output_dir}/{}" \; \
         >>$specdir/$package.spec
   fi
   popd >/dev/null
   if [ -d "$DIR/$package/SOURCES" ]; then
      rm -Rf $sourcedir
      cp -R "$DIR/$package/SOURCES" $rpmdir
   fi
   cd ../target
   $DP_HOME/profiles/package/redhat/dp_package.sh \
      --version $version \
      --release $release \
      --organization $organization \
      --project $prefix \
      --debug
   local ret_val=$?
   rm -Rf $rpmdir
   return $ret_val
}
