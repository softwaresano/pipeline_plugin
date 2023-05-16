#!/bin/bash

function format_file() {
  command -v xmllint >/dev/null || return 126
  xmllint --format "$file_name" 2>/dev/null
}

# Validate xml_format
function validate() {
  local formated_file
  formated_file=$(format_file) || return 1
  if ! diff "${file_name:?}" <(echo "${formated_file:?}"); then
    dp_log.sh "[INFO] Run ${BASH_SOURCE[0]} '${file_name:?}' to fix it"
    return 1
  fi
}

function xml_format_fix() {
  file_name=${1:?}
  local formated_file
  formated_file=$(format_file) || return 1
  echo "${formated_file:?}" >"${file_name:?}"
}

[[ $(readlink -f "$0") == $(readlink -f "${BASH_SOURCE[0]}") ]] && xml_format_fix "$@"
