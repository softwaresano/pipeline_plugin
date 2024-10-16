#!/bin/bash

# Validate if file is 
function validate() {
  if [ $(stat --format=%s "$file_name") -gt $((1024 * 1024)) ]; then
    dp_log.sh "[INFO] The file $file_name ($(du -hs "$file_name")) is larger than 1MB."
    return 1
  fi
}
