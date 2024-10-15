#!/bin/bash

# Validate if file contains space
function validate() {
  [[ "$file_name" =~ [[:space:]] ]] && return 0
  dp_log.sh "[INFO] Replace or remove whitespaces or tabs in $file_name"
  return 1
}
