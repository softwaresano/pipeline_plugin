#!/bin/bash
# Validate xml
function validate(){
  which xmllint 2>/dev/null >/dev/null || return 126
  xmllint $file_name  2>/dev/stdout
}
