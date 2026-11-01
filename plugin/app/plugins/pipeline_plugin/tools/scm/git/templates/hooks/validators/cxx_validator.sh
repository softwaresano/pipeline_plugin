#!/bin/bash

# Validate c
function cpp_validate() {
  [[ -x "${git_dir:?}"/tempdir/cppcheck.sh ]] || return 126
  "${git_dir:?}"/tempdir/cppcheck.sh "${file_name:?}"
}
