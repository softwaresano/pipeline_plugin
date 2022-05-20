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
  *) type_file=$(file "$file_name" | grep -Po '(?<=: ).*') ;;
  esac
  case $type_file in
  "Bourne-Again shell script, ASCII text executable") echo "${bash_validators}" ;;
  "Bourne-Again shell script text executable, ASCII text") echo "${bash_validators}" ;;
  "Bourne-Again shell script text executable") echo "${bash_validators}" ;;
  "Bourne-Again shell script, ASCII text executable, with very long lines") echo "${bash_validators}" ;;
  "POSIX shell script text executable") echo "sh shfmt shellcheck" ;;
  Makefile | Pipfile | Gemfile | package.json) echo "${type_file}" ;;
  Python*) echo "${py_validators}" ;;
  *) # By default, it uses the extension file to identify file type
    base_file_name=$(basename "$file_name")
    #get last suffix
    echo "${base_file_name##*.}"
    ;;
  esac
}

function individual_validator() {
  local file_name
  local validator
  local result_code
  local validation_error
  file_name=$1
  validator=$2
  validator_file="${validator_dir}/${validator}.sh"
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
  125) dp_log.sh "[WARNING] [${validator}] hook disabled for $file_name" ;;
  126) dp_log.sh "[WARNING] There is not any validator for $file_name" ;;
  0) dp_log.sh "[INFO]  [OK] [${validator}] $file_name" ;;
  *)
    dp_log.sh "[ERROR] [KO] [${validator}] $file_name"
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
