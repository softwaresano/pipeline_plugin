#!/bin/bash

# Validate python_file
function validate() {
  [[ -x .git/tempdir/erb_hook.sh ]] || return 126
  .git/tempdir/erb_hook.sh "${file_name:?}"
}
