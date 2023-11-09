#!/bin/bash

# Validate prettier
function validate() {
  [[ ${file_name:?} == *.min.js ]] && return 0
  command -v prettier &>/dev/null || return 126
  if prettier --no-color --check "${file_name:?}"|grep -q '^\[warn] '; then
    prettier "${file_name:?}"
    dp_log.sh "[INFO] prettier --write ${file_name:?} to fix it"
    return 1
  fi
}
