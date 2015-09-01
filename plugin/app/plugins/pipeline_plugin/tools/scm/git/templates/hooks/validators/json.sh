#!/bin/bash
# Validate json
function validate(){
  which jsonlint 2>/dev/null >/dev/null || return 126
  jsonlint -v $file_name 2>/dev/stdout|grep -v ": ok$"
  return ${PIPESTATUS[0]}
}
