#!/bin/bash

# Validate xml
function validate() {
  command -v xmllint >/dev/null || return 126
  xmllint "$file_name" 2>/dev/stdout
}
