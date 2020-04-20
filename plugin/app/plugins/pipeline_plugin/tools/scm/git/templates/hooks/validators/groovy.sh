#!/bin/bash
# Validate groovy file
function validate(){
  which npm-groovy-lint 2>/dev/null >/dev/null || return 126
  npm-groovy-lint -p "$(dirname "${file_name}")" -f "**/$(basename "${file_name}")" --failonerror
}
