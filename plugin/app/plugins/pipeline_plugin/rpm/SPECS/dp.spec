
Name:      dp
Summary:   Deployment pipeline plugin
Version:   %{versionModule}
Release:   %{releaseModule}
License:   GPL 3.0
Packager:  %{org_acronuym}
Group:     develenv
BuildArch: noarch
BuildRoot: %{_topdir}/BUILDROOT
Requires:  rpm-build createrepo python%{python3_version_nodots} python3-simplejson hostname yum-utils
AutoReq:   No
Vendor:    %{vendor}

#Compatible with rh5.5
%define _binary_filedigest_algorithm  1
%define _binary_payload 1

%define    develenv_project_id develenv
%define    package_name dp
%define    _home_dir_    /opt/ss/%{develenv_project_id}/dp
%define    src_dir $(dirname %{_sourcedir})/../

%description
This plugin implements the deployment pipeline.

%prep
# ---------------------------------------------------------------------------- #
# prep section:
# ---------------------------------------------------------------------------- #
rm -Rf %{buildroot}/%{_home_dir_}
%{__mkdir_p} %{buildroot}/%{_home_dir_}/temp
cd $(dirname %{_sourcedir})/../
for resource in $(ls|egrep -v "^target$|^rpm$"); do
   if [ -f $resource ]; then
      cp $resource %{buildroot}/%{_home_dir_}
   else
      cp -R $resource %{buildroot}/%{_home_dir_}
   fi
done;
mkdir -p %{buildroot}/usr/lib/rpm/macros.d/
mv %{buildroot}/%{_home_dir_}/profiles/package/redhat/macros.dp %{buildroot}/usr/lib/rpm/macros.d/

%clean
# ---------------------------------------------------------------------------- #
# clean section:
# ---------------------------------------------------------------------------- #
[ %{buildroot} != "/" ] && rm -rf %{buildroot}


%files
%defattr(-,%{develenv_project_id},%{develenv_project_id},-)
%{_home_dir_}
%attr(0644, root, root) /usr/lib/rpm/macros.d/macros.dp
%config(noreplace) %{_home_dir_}/config


%pre
# ---------------------------------------------------------------------------- #
# pre-install section:
# ---------------------------------------------------------------------------- #
# Create develenv user if not exists
# Creating develenv user if the installations is out of develenv
id -u %{develenv_project_id} || useradd -s /bin/bash %{develenv_project_id}
# >/dev/stdout >/dev/stderr redirect with a sudo
usermod -a -G tty %{develenv_project_id}
# ---------------------------------------------------------------------------- #
# post-install section:
# ---------------------------------------------------------------------------- #
%post
#Create Links to $targetLink directory
function linkFiles(){
   local targetLink=$1
   local resources=$2
   local currentDir=$PWD
   cd $targetLink
   if [ "$resources" != "" ]; then
      for resource in $resources; do
         linkResource="/$targetLink/$(echo $resource|sed s:"^\./":"":g)"
         # Delete if link is broken
         rm -Rf $(find -L  $linkResource -type l 2>/dev/null)
         if [ ! -f "$linkResource" ]; then
            mkdir -p $(dirname $linkResource) 
            ln -s $currentDir/$resource $linkResource
         fi
      done;
   fi
}
cd %{_home_dir_}
resources=$(find . -maxdepth 1 -name '*.sh')

linkFiles /usr/bin/ "$resources"
cd /usr/bin
rm -f pipeline.sh
ln -s %{_home_dir_}/admin/pipeline.sh

%postun
# ---------------------------------------------------------------------------- #
# post-uninstall section:
# ---------------------------------------------------------------------------- #
#Delete symbolic links createds in %post
function unLinkFiles(){
   cd /usr/bin/
   rm -Rf $(find -L dp_* -type l 2>/dev/null)
}
unLinkFiles
rm -Rf $(find -L pipeline.sh -type l 2>/dev/null)
