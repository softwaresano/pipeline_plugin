#!/bin/bash

# Validate python_file
function validate() {
  command -v black >/dev/null || return 126
  if ! black -v --diff --check "${file_name}"; then
    dp_log.sh "[INFO] Run black $file_name to fix it"
  return 1
 fi
}
