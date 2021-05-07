#!/bin/bash
# Validate typescript
function file_lock_validate(){
  [[ ${file_name} -nt $1 ]] && dp_log.sh "[ERROR] $1 is not syncronized with  ${file_name:?}" && return 1
  git ls-files --error-unmatch "${file_name:?}" &>/dev/null || (dp_log.sh "[ERROR] ${file_name:?} must be tracked by git. Run git add -f ${file_name:?}" && return 1)
}