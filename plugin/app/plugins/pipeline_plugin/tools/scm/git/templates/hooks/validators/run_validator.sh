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
function is_cdn_build() {
   [[ -s .git/techs ]]
}
function is_present_tech() {
  grep -Eq "^${1:?}$" .git/techs
}

# Return the function to file validate
function get_validator() {
  local bash_validators
  local type_file
  local file_name
  local py_validators
  local extra_bash_validators
  file_name=$1
  is_present_tech shell  && extra_bash_validators="code_style_shell lint_shell test_shell" || extra_bash_validators="shellcheck"
  bash_validators="bash shfmt ${extra_bash_validators:?}"
  py_validators="py black"
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
    is_present_tech docker && echo "lint_docker" || echo "dockerfile"
    return 0
    ;;
  esac
  case $file_name in
  *.md)
    is_present_tech markdown && echo "lint_markdown" || echo "md prettier"
    return 0
    ;;
  *.adoc)
    is_cdn_build && echo "compile_adoc" || echo "adoc"
    return 0
    ;;
  Makefile | *.mk)
    is_present_tech makefile && echo "test_makefile" || echo "Makefile"
    return 0
    ;;
  Pipfile | package.json) type_file="$file_name" ;;
  *.xml)
    echo "xml xml_format"
    return 0
    ;;
  *.spec)
    is_present_tech rpm && echo "lint_rpm package_rpm" || echo "spec"
    return 0
    ;;
  *.groovy | Jenkinsfile)
    is_present_tech groovy && echo "lint_groovy" || echo "groovy"
    return 0
    ;;
  Gemfile)
    is_present_tech "(ruby|gems|rake)" && echo "Gemfile lint_ruby" || echo "rb"
    return 0
    ;;
  *.rb|Rakefile)
    ruby_hooks=""
    is_present_tech rake && ruby_hooks=" test_rake"
    is_present_tech "(ruby|gems|rake)" && echo "lint_ruby${ruby_hooks} " || echo "rb"
    return 0
    ;;
  *.erb)
    is_present_tech "(ruby|gems|rake)"  && echo "lint_ruby" || echo "erb"
    return 0
    ;;
  *.yml | *.yaml)
    is_present_tech yaml && echo "lint_yaml" || echo "yaml"
    return 0
    ;;
  *.json)
    echo "json prettier"
    return 0
    ;;
  *.ts)
    is_present_tech typescript && echo "lint_typescript" || echo "prettier"
    return 0
    ;;
  *.css | *.html | *.htm | *.js)
    is_cdn_build && echo "code_style_prettier" || echo "prettier"
    return 0
    ;;
  *.cpp | *.c)
    is_present_tech "(cxx|cmake)"  && echo "code_style_cxx lint_cxx" || echo "cxx"
    return 0
    ;;
  *.pp)
    is_present_tech "puppet"  && echo "pp lint_puppet" || echo "pp"
    return 0
  ;;
  *) type_file=$(file "$file_name" | grep -Po '(?<=: ).*') ;;
  esac
  case $type_file in
  "Bourne-Again"*) echo "${bash_validators}" ;;
  "POSIX shell"*) echo "sh shfmt shellcheck" ;;
  Pipfile | package.json) echo "${type_file}" ;;
  *Python* | *python*)
    is_cdn_build && echo "${py_validators:?} code_style_python lint_python test_python" || echo "${py_validators:?}"
    ;;
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
  local validator_error=0
  if [[ -f "${validator_dir:?}/${validator:?}.sh" ]]; then
    execute_validator "${file_name:?}" "${validator:?}" || validator_error=1
  fi
  if is_cdn_build && [[ -f ${CDN_BUILD_LIB}/hooks/${validator}.sh ]]; then
    execute_validator "${file_name:?}" "${validator:?}" "${CDN_BUILD_LIB:?}"/hooks "cdn-build" || validator_error=1
  fi
  if [[ -f ./hooks/${validator}.sh ]]; then
    execute_validator "${file_name:?}" "${validator:?}" ./hooks/ "component" || validator_error=1
  fi
  return "${validator_error:?}"
}
function hook_log() {
  dp_log.sh "${1:?}" |& tee -a .git/hooks.log
}

function execute_validator() {
  local file_name
  local validator
  local result_code
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
      local hook_message_suffix=''
      if [[ "$(echo -n "$file_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" != '' ]]; then
        hook_message_suffix=" for ${file_name:?}"
      fi
      dp_log.sh " >>> HOOK: Running ${validator_name:?}${hook_message_suffix}"
      validate
      result_code=$?
    else
      result_code=$?
    fi
  else
    result_code=126
  fi
  case $result_code in
  125)
    if [[ ${file_name:?} == " " ]]; then
      hook_log "[WARNING] [${validator_name:?}] hook disabled"
      return 0
    fi
    hook_log "[WARNING] [${validator_name:?}] hook disabled for $file_name"
    ;;
  126) hook_log "[WARNING] There is not any validator for $file_name" ;;
  0) hook_log "[INFO]  [OK] [${validator_name:?}] $file_name" ;;
  *)
    hook_log "[ERROR] [KO] [${validator_name:?}] $file_name"
    n_errors=$((n_errors + 1))
    errors_files="${errors_files}\n  - ${file_name}"
    error_file=${file_name}
    ;;
  esac
  return $result_code
}

function run_validator() {
  local file_name
  local validator
  local result_code
  file_name=$1
  validator=$2
  if [[ ${validator} == '' ]]; then
    validator=$(get_validator "${file_name}")
  fi
  for i in $validator; do
    individual_validator "$file_name" "$i"
  done
}
