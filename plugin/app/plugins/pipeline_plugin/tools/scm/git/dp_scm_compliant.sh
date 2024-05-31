#!/bin/bash
# Return JIRA_ID associated with a branch name. Only if the repo belongs to
# <project_name> parameter
function get_repo_project_name(){
  basename $(git remote show -n origin | grep Fetch | cut -d: -f2-)|cut -d'-' -f1
}
function get_git_prefix_message(){
  project_name=$1
  jira_prefix=$2
  repo_project_name=$(get_repo_project_name)
  [[ "$repo_project_name" != "$project_name" ]] && return 0
  jira_prefix_id="$jira_prefix-[0-9]+_"
  branch_stability_type=$(dp_branch_type.sh)
  if [[ "$branch_stability_type" == "unstable" || "$branch_stability_type" == "other" ]]; then
    IFS="/"
    set $current_branch
    unset IFS
    branch_type=$1
    branch_name=$2
    branch_types="feature|bug|hotfix|task"
    [[ "${current_branch}" =~ ^(${branch_types})/${jira_prefix}-[0-9]+_ ]] && echo "$branch_name"|sed 's:_.*::g' && return 0
    [[ "$current_branch" == 'HEAD' ]] && [[ "${JOB_URL}" != '' ]] && return 0
    [[ "$jira_prefix" == "WITHOUT_JIRA" ]] && [[ "$branch_stability_type" == "unstable" ]] && echo "" && return 0
    dp_log.sh "[ERROR] [$current_branch] is not a valid $project_name branch name."
    [[ "$jira_prefix" != "WITHOUT_JIRA" ]] && \
        dp_log.sh "[ERROR] The valid branch name is: <$branch_types>/$jira_prefix-XXXX_$branch_name, where XXXX is the jira-id associated with a jira task" || \
        dp_log.sh "[ERROR] The valid branch name is: <$branch_types>/$([[ "$branch_name" == "" ]] && echo $current_branch || echo $branch_name)"
    return 1
  fi
}
project_name=$(get_repo_project_name)
projects_id_dir=$(git rev-parse --show-toplevel)/.git/hooks/projects_id
jira_prefix_file=$projects_id_dir/$project_name/jira_prefix
jira_prefix=$(cat $jira_prefix_file 2>/dev/null)

if [[ "$jira_prefix" == "" ]]; then
  if [[ "$project_name" == "cdn" ]]; then
    jira_prefix="(PTWOPCDN|PTWOPCDNTC|TCDNOPTSCB|GMETRICS|OPSSUP|VTOOLS)"
  else
    dp_log.sh "[ERROR] There aren't any jira_prefix for $project_name organization"
    dp_log.sh "[ERROR] Add jira-prefix (Ex: PTWOPCDN) in $jira_prefix_file file or assigns WITHOUT_JIRA to disable jira_prefix"
    exit 1
  fi
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)
[[ "${current_branch}" =~ ^dependabot ]] && return 0
get_git_prefix_message "$project_name" "$jira_prefix"
