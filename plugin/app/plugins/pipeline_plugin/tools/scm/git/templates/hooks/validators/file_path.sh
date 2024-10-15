#!/bin/bash

# Validate if file contains space
function validate() {
  if [[ "$file_name" =~ [[:space:]] ]]; then
    dp_log.sh "[INFO] Replace or remove whitespaces or tabs in $file_name"
    return 1
  fi
}
