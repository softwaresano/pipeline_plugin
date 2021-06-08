#!/bin/bash
# Validate sh
function validate(){
  sh -n "$file_name" 2>/dev/stdout && \
    shellcheck -x "$file_name" 2>/dev/stdout && \
    shfmt -d -s -i 2 "$file_name"
}
