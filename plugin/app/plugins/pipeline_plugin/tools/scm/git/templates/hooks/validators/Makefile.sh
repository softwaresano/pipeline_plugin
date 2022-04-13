#!/bin/bash
# Validate makefile
function validate(){
  make -n -f $file_name 2>/dev/stdout
  if [[ "${file_name}" == "Makefile" ]]; then
     grep "CDN_BUILD_LIB" "${file_name:?}" || return 0
     rm -f target/executions/test_makefile
     make test_makefile
  fi
}
