#!/bin/bash
function validate() {
  [[ ! -f "${git_dir:?}"/tempdir/check_docs.sh ]] && return 0
  if [[ -f "${git_dir:?}"/tempdir/check_docs ]]; then
    "${git_dir:?}"/tempdir/check_docs.sh  && rm -f "${git_dir:?}"/tempdir/check_docs
  fi
}
