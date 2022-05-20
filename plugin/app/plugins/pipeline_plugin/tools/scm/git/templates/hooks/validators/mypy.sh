#!/bin/bash

# Validate python_file
function validate() {
  [[ -x .git/tempdir/mypy.sh ]] || return 126
  .git/tempdir/mypy.sh "${file_name:?}"
}
