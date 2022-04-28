#!/bin/bash

# Validate python_file
function validate() {
  command -v mypy >/dev/null || return 126
  mypy  "${file_name}" || return 1
 fi
}
