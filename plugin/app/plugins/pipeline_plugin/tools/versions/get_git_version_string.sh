#!/bin/bash
#
# Bash lib to know the RPM version and revision from a PDIHub repository
# Call method get_rpm_version_string to obtain them for rpmbuild
#

shopt -s extglob

get_branch()
{
    git rev-parse --abbrev-ref HEAD
}

function get_git_branch_type(){
    local branch=$1
    case $branch in
        feature/*|bug/*|hotfix/*|task/*|test/*) echo "unstable";;
        release/+(+([[:digit:]])\.)+([[:digit:]]) ) echo "release" ;;
        develop) echo "develop";;
        master) echo "master";;
        *) echo "other";;
    esac
}
## PDI specific functions according the pdihub workflow
get_branch_type()
{
    get_git_branch_type "$(get_branch)"
}

get_stable_parent_branch() {
  git rev-parse --abbrev-ref HEAD|grep -E '(develop|release/|master).*' && return;
  git show-branch -a 2>/dev/null|grep '\*'|grep -E ' \[(develop|release/|master).*] '|\
    head -1|grep -Po '(?<=\[).*(?=])'|sed 's/[\^|~].*//'
}

get_target_branch_type()
{
    if [ -z $ghprbTargetBranch ]; then
        get_git_branch_type "$(get_stable_parent_branch)"
    else
        get_git_branch_type "$ghprbTargetBranch"
    fi
}


get_version_string()
{   getCacheProperty 'cache_version_string' && return 0
    if [[ $(is_pdi_compliant) -eq 0 ]]; then # Not PDI compliant, return a dummy version
        echo "HEAD-$(git log|grep ^commit|wc -l)-g$(git log --pretty=format:'%h' -1)"
        return
    fi
    local branch describe_all describe_tags version ancestor
    describe_all="$(git describe --all --long)"
    describe_tags="$(git describe --tags --long 2>/dev/null)"
    [[ "${describe_tags}" == "${describe_all#*/}" ]] && version="${describe_tags%/*}" || version="${version#*/}"
    case $(get_target_branch_type) in
        develop|master|unstable)
           ## if we are in develop use the total count of commits
           ###  version=$(git describe --tags --long --match */KO)
           version=$(for i in $(git tag|grep "/KO"|sort -Vr); do git describe --tags --long --match $i 2>/dev/null && break; done;)
           git_root_dir=$(git rev-parse --show-toplevel)
           local major_version
           local ko_version
           local tag_file
           ko_version=$(echo ${version}|cut -d'/' -f1)
           major_version=$(grep $(grep "refs/tags/${ko_version}/KO" ${git_root_dir}/.git/packed-refs|awk '{print $1}') ${git_root_dir}/.git/packed-refs |grep -Po "(?<=refs/tags/).*(?=/KO)"|sort -V|tail -1)
           cache_version_string="${major_version}-${version#*KO-}"
        ;;
        release)
           if [ -z $ghprbTargetBranch ]; then
              version=$(get_branch)
           else
              # Jenkins job's is triggered by pr
              version=$ghprbTargetBranch
           fi
           version=$(git describe --tags --long --match ${version#release/*}/KO)
           cache_version_string="${version%/*}-${version#*KO-}"
        ;;
        other)
            ## We are in detached mode, use the last KO tag
            version=$(for i in $(git tag|grep "/KO"|sort -Vr); do git describe --tags --long --match $i 2>/dev/null && break; done;)
            cache_version_string="${version%/*}-${version#*KO-}"
        ;;
        *)
           # RMs don't stablish any standard here, we use seconds since 1970-01-01 00:00:00 UTC as version
           version=$(date +%s)
           # Release will give info about branch and sha
           branch_name=$(get_branch)
           
           rel=$(git log|grep ^commit|wc -l)_${branch_name#*/}
           cache_version_string="${version}-${rel}-g$(git log --pretty=format:'%h' -1)"
    esac
    setCacheProperty 'cache_version_string'
}

## Parse the version string and sanitize it
## to use it you can do, for example:
## ># read ver rel < <(get_rpm_version_string)
get_rpm_version_string() {
    local version_string ver rel
    version_string="$(get_version_string)"
    ver="${version_string%-*-*}"
    rel="${version_string:$((${#ver}+1))}"
    echo "${ver//[[:space:]-\/#]}" "${rel//[-]/.}"
}
#To be more compliant with pipeline and give each param alone
get_version() {
    echo $(get_rpm_version_string)|awk '{print $1}'
}

get_revision() {
    echo $(get_rpm_version_string)|awk '{print $2}'
}

is_pdi_compliant()
{   git rev-parse --show-toplevel 2>/dev/null 1>/dev/null
    if [ "$?" != "0" ]; then
        echo 0
        return ;
    fi
    case $(get_branch_type) in
    "other")
       # Maybe we are on detached mode but also are compliant
       # See if there's a tag (annotated or not) describing a Kick Off
       git describe --tags --match */KO >/dev/null 2>/dev/null
       if [ $? -eq 0 ]; then
         echo 1
       else
         echo 0
       fi
    ;;
    "release")
        ver=$(get_branch)
        # remove the leading release/ if necessary
        ver=${ver#release/*}
        # see if there's a tag (annotated or not) describing its Kick Off
        git describe --tags --match ${ver}/KO >/dev/null 2>/dev/null
        if [ $? -eq 0 ]; then
            echo 1
        else
            echo 0
        fi
    ;;
    "develop")
        # see if there's a tag (annotated or not) describing a Kick Off
        git describe --tags --match */KO >/dev/null 2>/dev/null
        if [ $? -eq 0 ]; then
            echo 1
        else
            echo 0
        fi
    ;;
    *)  echo 1 ;;
   esac
}
