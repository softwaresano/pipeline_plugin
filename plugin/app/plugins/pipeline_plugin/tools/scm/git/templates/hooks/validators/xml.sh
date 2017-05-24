#!/bin/bash
# Validate xml
function validate(){
  source $validator_dir/non_ascii.sh
  is_ascii || return 1
  which xmllint 2>/dev/null >/dev/null || return 126
  xmllint $file_name  2>/dev/stdout
}
