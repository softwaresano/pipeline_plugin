#!/bin/bash

# Validate shell formater
function validate() {
  if ! shfmt -d -s -i 2 "$file_name"; then
    dp_log.sh "[INFO] Run shfmt -i 2 -w -s $file_name to fix it"
    return 1
  fi
}
