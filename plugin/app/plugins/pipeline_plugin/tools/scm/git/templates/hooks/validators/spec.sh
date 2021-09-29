#!/bin/bash

# Validate specfile
function is_rpm_spec_file() {
  [[ "$(grep -c '^%files' "$file_name")" == "1" ]] && return 0
}

function validate() {
  local exit_code=0
  is_rpm_spec_file || return 126
  command -v rpmlint >/dev/null || return 126
  rm -f rpmlint.log
  rpmlint "$file_name" | tee -a rpmlint.log
  #filter by number errors. RPM_SOURCE_DIR isnot a error
  exit_code=$(<rpmlint.log grep -v "E: use-of-RPM_SOURCE_DIR$" | grep ":" | cut -d':' -f2- | grep -c -v " W:")
  rm -f rpmlint.log
  #string to integer
  return $((exit_code))
}
