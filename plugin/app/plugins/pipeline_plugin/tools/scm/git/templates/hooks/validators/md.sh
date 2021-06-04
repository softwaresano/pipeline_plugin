#!/bin/bash
# Validate markdown
function validate(){
  command -v mdl >/dev/null || return 0
  if [[ -f "${CDN_BUILD_LIB}/linters/mdl.rb" ]]; then
    mdl -s "${CDN_BUILD_LIB:?}/linters/mdl.rb" "${FILE_NAME}"
  else 
    mdl "${FILE_NAME}"
  fi
}
