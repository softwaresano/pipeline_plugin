#!/bin/bash

# Validate groovy file
function validate() {
  command -v npm-groovy-lint >/dev/null || return 126
  npm-groovy-lint -p "$(dirname "${file_name}")" -f "**/$(basename "${file_name}")" --failonerror
}
