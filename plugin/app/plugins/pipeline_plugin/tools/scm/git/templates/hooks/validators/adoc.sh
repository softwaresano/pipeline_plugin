#!/bin/bash

# Validate adoc_file
function validate() {
  [[ ${file_name:?} == *.tpl.adoc ]] && return 126
  [[ -x .git/tempdir/adoc.sh ]] || return 126
  .git/tempdir/adoc.sh "${file_name:?}" && touch .git/tempdir/check_docs
}
