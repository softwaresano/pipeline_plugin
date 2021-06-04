#!/bin/bash
# Validate groovy file
function validate(){
  command -v npm-groovy-lint >/dev/null || return 126
  npm-groovy-lint -p "$(dirname "${FILE_NAME}")" -f "**/$(basename "${FILE_NAME}")" --failonerror
}
