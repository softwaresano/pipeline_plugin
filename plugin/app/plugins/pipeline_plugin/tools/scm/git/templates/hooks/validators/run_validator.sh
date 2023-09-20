#!/bin/bash
#shellcheck source=plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/run_validator.sh
# Run validator
function is_hook_enabled() {
  if [[ $DISABLE_HOOK == "ALL" ]] ||
    [[ $DISABLE_HOOK == "all" ]] ||
    [[ $DISABLE_HOOK == "$1" ]]; then
    return 125
  fi
}

# Return the function to file validate
function get_validator() {
  local bash_validators
  local type_file
  local file_name
  local py_validators
  file_name=$1
  bash_validators="bash shfmt shellcheck"
  py_validators="py black mypy pylint"
  case $(basename "$file_name") in
  "sonar-project.properties")
    echo "sonar-project"
    return 0
    ;;
  "thirdparty-rpms.txt")
    echo "thirdparty-rpms"
    return 0
    ;;
  "Dockerfile")
    echo "dockerfile"
    return 0
    ;;
  esac
  case $file_name in
  Makefile | Pipfile | Gemfile | package.json) type_file="$file_name" ;;
  *.mk) type_file="Makefile";;
  *.adoc) type_file="adoc" ;;
  *.xml)
    echo "xml xml_format"
    return 0
    ;;
  *) type_file=$(file "$file_name" | grep -Po '(?<=: ).*') ;;
  esac
  case $type_file in
  "Bourne-Again shell script, ASCII text executable") echo "${bash_validators}" ;;
  "Bourne-Again shell script text executable, ASCII text") echo "${bash_validators}" ;;
  "Bourne-Again shell script text executable") echo "${bash_validators}" ;;
  "Bourne-Again shell script, ASCII text executable, with very long lines") echo "${bash_validators}" ;;
  "POSIX shell script text executable") echo "sh shfmt shellcheck" ;;
  Makefile | Pipfile | Gemfile | package.json) echo "${type_file}" ;;
  *Python* | *python*) echo "${py_validators}" ;;
  *) # By default, it uses the extension file to identify file type
    base_file_name=$(basename "$file_name")
    #get last suffix
    echo "${base_file_name##*.}"
    ;;
  esac
}

function individual_validator() {
  local file_name=${1:?}
  local validator=${2:?}
  if [[ -f "${validator_dir:?}/${validator:?}.sh" ]]; then
     execute_validator "${file_name:?}" "${validator:?}" || return 1
  fi
  if grep -q "\$(CDN_BUILD_LIB)" Makefile 2 >/dev/null && [[ -f ${CDN_BUILD_LIB}/hooks/${validator}.sh ]]; then
    execute_validator "${file_name:?}" "${validator:?}" "${CDN_BUILD_LIB:?}"/hooks "cdn-build" || return 1
  fi
  if [[ -f ./hooks/${validator}.sh ]]; then
    execute_validator "${file_name:?}" "${validator:?}" ./hooks/ "component" || return 1
  fi
}
function execute_validator() {
  local file_name
  local validator
  local result_code
  local validation_error
  local validator_scripts_dir
  local prefix
  local validator_name
  file_name=${1:?}
  validator=${2:?}
  validator_scripts_dir=${3:-${validator_dir:?}}
  prefix=${4}
  [[ ${prefix} == "" ]] && validator_name="${validator:?}" || validator_name="${validator:?}(${prefix})"
  validator_file="${validator_scripts_dir}/${validator}.sh"
  if [[ -f $validator_file ]]; then
    source "$validator_file"
    if is_hook_enabled "${file_name}"; then
      validation_error=$(validate)
      result_code=$?
    else
      result_code=$?
    fi
  else
    result_code=126
  fi
  case $result_code in
  125) if [[ ${file_name:?} == " " ]]; then 
	  dp_log.sh "[WARNING] [${validator_name:?}] hook disabled" 
	  return 0
       fi
       dp_log.sh "[WARNING] [${validator_name:?}] hook disabled for $file_name" 
       ;;
  126) dp_log.sh "[WARNING] There is not any validator for $file_name" ;;
  0) dp_log.sh "[INFO]  [OK] [${validator_name:?}] $file_name" ;;
  *)
    dp_log.sh "[ERROR] [KO] [${validator_name:?}] $file_name"
    echo "==================================================================="
    echo -en "${validation_error}\n"
    n_errors=$((n_errors + 1))
    errors_files="${errors_files}\n  - ${file_name}"
    error_file=${file_name}
    echo "==================================================================="
    ;;
  esac
  return $result_code
}

function run_validator() {
  local file_name
  local validator
  local result_code
  local validation_error
  file_name=$1
  validator=$2
  if [[ ${validator} == '' ]]; then
    validator=$(get_validator "${file_name}")
  fi
  for i in $validator; do
    individual_validator "$file_name" "$i"
  done
}
