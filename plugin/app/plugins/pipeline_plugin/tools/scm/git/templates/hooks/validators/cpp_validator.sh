#!/bin/bash

# Validate c
function cpp_validate() {
  [[ -x .git/tempdir/cppcheck.sh ]] || return 126
  .git/tempdir/cppcheck.sh "${file_name:?}"
}
