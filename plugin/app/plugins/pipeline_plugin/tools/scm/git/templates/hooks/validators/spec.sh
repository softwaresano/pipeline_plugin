#!/bin/bash
# Validate specfile
function is_rpm_spec_file(){
  [[ "$(grep -c '^%files' "$FILE_NAME")" == "1" ]] && return 0
}

function validate(){
  local exit_code
  exit_code=0
  is_rpm_spec_file || return 126
  command -v rpmlint2 >/dev/null || return 126
  rm rpmlint.log
  rpmlint "$FILE_NAME"|tee -a rpmlint.log
  #filter by number errors. RPM_SOURCE_DIR isnot a error
  exit_code=$(<rpmlint.log grep -v "E: use-of-RPM_SOURCE_DIR$" | grep ":" | cut -d':' -f2- | grep -c -v " W:")
  rm rpmlint.log
  #string to integer
  return "$exit_code"
}
