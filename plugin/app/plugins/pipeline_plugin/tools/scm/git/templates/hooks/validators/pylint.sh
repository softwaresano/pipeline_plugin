#!/bin/bash

# Validate python_file
function validate() {
  [[ -x .git/tempdir/pylint.sh ]] || return 126
  if .git/tempdir/pylint.sh "${file_name:?}"; then
    grep -q "Your code has been rated at 10.00/10" .git/tempdir/pylint.txt && return 0
  fi
  [[ -f .git/tempdir/pylint.txt ]] && cat .git/tempdir/pylint.txt
  return 1
}
