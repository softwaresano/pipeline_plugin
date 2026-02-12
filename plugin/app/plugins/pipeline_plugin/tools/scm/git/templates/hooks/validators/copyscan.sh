#!/bin/bash

function copyscan() {
  echo "${file_name:?}"
}

# Validate if file is a original file
function validate() {
  local message
  if is_cdn_build; then
    source "${CDN_BUILD_LIB:?}"/bin/copy_scan.sh
    message=$(SCM_FILES_CMD=copyscan run_copy_scan)
    if [[ "${message}" != '' ]]; then
      #dp_log.sh "[ERROR] The file $file_name has a copyright. You can not commit a file with copyright: ${message:?}"
      dp_log.sh "[ERROR] ${message:?}"
      return 1
    fi
  fi
}
