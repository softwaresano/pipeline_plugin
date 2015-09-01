
Name:      dp-jenkins
Summary:   Deployment pipeline plugin
Version:   %{versionModule}
Release:   %{releaseModule}
License:   GPL 3.0
Packager:  %{org_acronuym}
Group:     develenv
BuildArch: noarch
BuildRoot: %{_topdir}/BUILDROOT
Requires:  ss-develenv-dp
Vendor:    %{vendor}

%define    develenv_project_id develenv
%define    package_name dp
%define    jobs_target_dir  /var/%{develenv_project_id}/jenkins/jobs
%define    src_dir $(dirname %{_sourcedir})/../

%description
This plugin implements the deployment pipeline.

%prep
cd $(dirname %{_sourcedir})/../
# Jenkins jobs
rm -Rf %{buildroot}/%{jobs_target_dir}
%{__mkdir_p} %{buildroot}/%{jobs_target_dir}


%{__cp} -r %{src_dir}/../../../../plugin/app/hudson/jobs/* %{buildroot}/%{jobs_target_dir}

%clean
[ %{buildroot} != "/" ] && rm -rf %{buildroot}


%files
%defattr(-,%{develenv_project_id},%{develenv_project_id},-)
%{jobs_target_dir}

%post
# ---------------------------------------------------------------------------- #
# post-install section:
# ---------------------------------------------------------------------------- #
#Enable access to jenkins jobs configuration via http://../develenv/config/jenkins/jobs
SELinux=$(sestatus |grep "SELinux status:"|cut -d':' -f2|awk '{print $1}')
_log "[INFO] Selinux: $SELinux"
if [ "$SELinux" == "enabled" ]; then
    _log "[INFO] Enable access to jenkins jobs configuration via http://$(hostname)/%{develenv_project_id}/config/jenkins/jobs/"
    chcon -R --type=httpd_sys_content_t %{jobs_target_dir}/pipeline-ADMIN-*
fi
_log "[WARNING] Access to http://$(hostname)/jenkins/reload to reload jenkins with the pipeline jobs"

%postun
# ---------------------------------------------------------------------------- #
# post-uninstall section:
# ---------------------------------------------------------------------------- #
#Delete symbolic links createds in %post
function unLinkFiles(){
   cd /usr/bin/
   rm -Rf $(find -L  dp_* -type l 2>/dev/null)
}
unLinkFiles
rm -Rf $(find -L  pipeline.sh -type l 2>/dev/null)

%changelog
