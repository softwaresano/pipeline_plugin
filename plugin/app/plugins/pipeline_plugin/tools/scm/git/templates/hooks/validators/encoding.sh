#!/bin/bash
# Run encoding

function get_encoding_validator() {
  local file_name
  local encoding_validator
  local type_file
  file_name=$1
  encoding_validator=""
  [[ $file_name =~ ^Makefile|\.mk$ ]] && type_file='text/x-makefile' || type_file=$(file --mime "$file_name" | awk '{print $2}')
  case $type_file in
  "text/x-makefile") ;;
  *) if [[ $type_file == text/* ]]; then
    echo "non_ascii"
    return 0
  fi ;;
  esac
  return 1
}

function validate() {
  local encoding_validator
  encoding_validator=$(get_encoding_validator "$file_name")
  if [[ ${encoding_validator} != '' ]]; then
    #shellcheck source=./plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/pre-commit
    #shellcheck source=./plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/non_ascii_validator.sh
    source "${validator_dir}/${encoding_validator}_validator.sh"
    encoding_validate "$file_name"
  fi
}
