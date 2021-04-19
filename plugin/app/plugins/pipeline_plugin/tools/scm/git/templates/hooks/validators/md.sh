#!/bin/bash
# Validate markdown
function validate(){
  which mdl 2>/dev/null >/dev/null || return 0
  if [[ -f ${CDN_BUILD_LIB}/linters/mdl.rb ]]; then
    mdl -s ${CDN_BUILD_LIB:?}/linters/mdl.rb "${file_name}"
  else 
    mdl "${file_name}"
  fi
}
