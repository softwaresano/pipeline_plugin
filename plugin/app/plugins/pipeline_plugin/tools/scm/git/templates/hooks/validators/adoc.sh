#!/bin/bash

# Validate adoc_file
function validate() {
  [[ -x .git/tempdir/adoc.sh ]] || return 126
  .git/tempdir/adoc.sh "${file_name:?}"
}
