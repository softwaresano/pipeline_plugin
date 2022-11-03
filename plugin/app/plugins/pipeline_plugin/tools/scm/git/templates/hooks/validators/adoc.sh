#!/bin/bash
# Validate adoc_file
function validate() {
  [[ ${file_name:?} == *.tpl.adoc ]] && return 126
  if [[ ! -x .git/tempdir/adoc.sh ]] && grep -q CDN_BUILD_LIB Makefile; then
    dp_log.sh "[INFO] Run make check_docs to check ${file_name:?}"
    return 1
  fi

  [[ -x .git/tempdir/adoc.sh ]] || return 126
  .git/tempdir/adoc.sh "${file_name:?}" && touch .git/tempdir/check_docs
}

