#!/bin/bash

# Validate if file is 
function validate() {
  [ $(stat --format=%s "$file_name") -lt $((1024 * 1024)) ] && return 0
  dp_log.sh "[INFO] The file $file_name is larger than 1MB."
  return 1
}
