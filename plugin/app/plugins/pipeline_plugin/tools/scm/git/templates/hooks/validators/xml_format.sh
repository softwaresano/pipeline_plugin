#!/bin/bash

# Validate xml_format
function validate() {
  command -v xmllint >/dev/null || return 126
  local xml_formated_file="${TMPDIR:-/tmp}"/xmllint_format.xml
  rm -f "${xml_formated_file:?}"
  xmllint --format "$file_name" 2>/dev/stdout > "${xml_formated_file:?}" || return 1
  if ! diff "${file_name:?}" "${xml_formated_file:?}"; then
    dp_log.sh "[INFO] Run xmllint --format '${file_name:?}' to fix it"
    return 1
  fi
}
