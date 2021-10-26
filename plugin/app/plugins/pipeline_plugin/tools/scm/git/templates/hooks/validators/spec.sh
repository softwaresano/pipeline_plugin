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
  (if [[ -f  "${CDN_BUILD_LIB}/linters/rpmlintrc" ]]; then
    rpmlint -f  "${CDN_BUILD_LIB}/linters/rpmlintrc" "$file_name"
  else
    rpmlint "$file_name"
  fi)|tee rpmlint.log
  grep -Eq "0 errors, 0 warnings\.$" rpmlint.log && exit_code=0 || exit_code=1
  rm -f rpmlint.log
  return $((exit_code))
}
