#!/bin/bash
function validate() {
  [[ ! -f .git/tempdir/check_docs.sh ]] && return 0
  if [[ -f .git/tempdir/check_docs ]]; then
    .git/tempdir/check_docs.sh  && rm -f .git/tempdir/check_docs
  fi
}
