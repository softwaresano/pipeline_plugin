#!/bin/bash
# Validate bash
function validate() {
  bash -n "$file_name" 2>/dev/stdout || return 1
  if ! shfmt -d -s -i 2 "$file_name"; then
    dp_log.sh "[ERROR] shfmt. Run shfmt -i 2 -w -s $file_name to fix it"
    return 1
  fi
  shellcheck -x -s bash "$file_name" 2>/dev/stdout
}