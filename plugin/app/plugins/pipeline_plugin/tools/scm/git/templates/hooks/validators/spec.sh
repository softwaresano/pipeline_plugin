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
  rpmlint "$file_name"|tee rpmlint.log
  grep -Eq "0 errors, 0 warnings\.$" rpmlint.log && exit_code=0 || exit_code=1
  rm -f rpmlint.log
  return $((exit_code))
}
