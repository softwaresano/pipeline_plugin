#!/bin/bash
# Return JIRA_ID associated with a branch name. Only if the repo belongs to
# <project_name> parameter
function get_repo_project_name(){
  git tag |grep -Po '.*(?=/Project$)'
}

function get_git_prefix_message() {
  local project_name=${1:?}
  local current_branch=${2:?}
  local jira_prefix=${3:?}

  if [[ ${current_branch:?} =~ ${jira_prefix:?} ]]; then
    echo "${current_branch:?}"|grep -Po '(?<=/).*'|cut -d'_' -f1 || true
    return 0
  fi
  dp_log.sh "[ERROR] [$current_branch] is not a valid $project_name branch name."
  if [[ "$jira_prefix" != "WITHOUT_JIRA" ]]; then
    dp_log.sh "[ERROR] The valid branch name is: ${jira_prefix:?}"
    return 1
  fi
}

project_name=$(get_repo_project_name)
projects_id_dir=$(git rev-parse --show-toplevel)/.git/hooks/projects_id
jira_prefix_file="$projects_id_dir/$project_name"/jira_prefix
if [[ "${jira_prefix}" == '' ]]; then
  jira_prefix=$(cat "$jira_prefix_file" 2>/dev/null)
fi

if [[ "$jira_prefix" == "" ]]; then
  if [[ "$project_name" == "cdn" ]]; then
    jira_prefix='^(develop|master|release/[0-9]{2}\.[0-9]{1,2}\.[0-9]{3}|(feature|task|hotfix|bug)/(PTWOPCDN|PTWOPCDNTC|TCDNOPTSCB|GMETRICS|OPSSUP|VTOOLS)-[0-9]+_.+)$'
  else
    dp_log.sh "[ERROR] There aren't any jira_prefix for $project_name organization"
    dp_log.sh "[ERROR] Add jira-prefix (Ex: PTWOPCDN) in $jira_prefix_file file or assigns WITHOUT_JIRA to disable jira_prefix"
    exit 1
  fi
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
[[ "${current_branch}" =~ ^dependabot ]] && return 0
get_git_prefix_message "${project_name:?}" "${current_branch:?}" "$jira_prefix"
