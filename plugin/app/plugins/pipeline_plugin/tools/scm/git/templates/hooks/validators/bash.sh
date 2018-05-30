#!/bin/bash
# Validate bash
function validate(){
  source $validator_dir/non_ascii.sh
  is_ascii && bash -n $file_name 2>/dev/stdout && shellcheck $file_name 2>/dev/stdout
}
