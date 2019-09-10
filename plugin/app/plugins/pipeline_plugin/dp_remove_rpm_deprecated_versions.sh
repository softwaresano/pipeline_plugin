#!/bin/bash
[ -z $DP_HOME ] && DP_HOME=$(python2 -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0/..)
### HELP section
dp_help_message='Only the newest rpm in a repo directory.

Usage: dp_remove_rpm_deprecated_version.sh <directory>'

source $DP_HOME/dp_help.sh $*
### END HELP section

function remove_deprecated_versions(){
    local directory=$1 # Directory with rpm version
    local rpm_file
    local dir_temp=~/temp/$directory
    rm -rf $dir_temp
    mkdir -p $dir_temp/rpms
    #First the newest
    ls -t $directory/*.rpm > $dir_temp/rpm_list
    # One rpm with all versions
    while read rpm_file; do
        rpm_name=$(rpm -qp --queryformat "[%{NAME}]" $rpm_file 2>/dev/null)
        rpm_arch=$(rpm -qp --queryformat "[%{ARCH}]" $rpm_file 2>/dev/null)
        rpm_version_id=$(rpm -qp --queryformat "[%{EPOCH} %{VERSION} %{RELEASE}]" $rpm_file 2>/dev/null|sed s:"^(none)":"0":g)
        mkdir -p $dir_temp/rpms/$rpm_arch/
        local rpm_file_aux=$dir_temp/rpms/$rpm_arch/$rpm_name
        if ! [ -f $rpm_file_aux ]; then
           echo "$rpm_version_id|$rpm_file" > $rpm_file_aux
        else
           local last_rpm_version_id=$(cat $rpm_file_aux|cut -d'|' -f1)
           rpmdev-vercmp $last_rpm_version_id $rpm_version_id >/dev/null
           if [ $? == 12 ]; then
              # Remove old_version
              local old_rpm_file=$(cat $rpm_file_aux|cut -d'|' -f2)
              echo $old_rpm_file is deprecated and will be removed
              rm $old_rpm_file
              echo "$rpm_version_id|$rpm_file" > $rpm_file_aux
           else
              echo $rpm_file is deprecated and will be removed
              rm $rpm_file
           fi
        fi
    done < "$dir_temp/rpm_list"
}

if [ $# != 1 ]; then
   dp_log.sh "[ERROR] <directory> parameter is mandatory"
   $0 --help
   exit 1
fi
remove_deprecated_versions $1