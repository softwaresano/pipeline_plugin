#!/bin/bash
# Validate xml
function validate(){
  command -v xmllint >/dev/null || return 126
  xmllint "$FILE_NAME"  2>/dev/stdout
}
