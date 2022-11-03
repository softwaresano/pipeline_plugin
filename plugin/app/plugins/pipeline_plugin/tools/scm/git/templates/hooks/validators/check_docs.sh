#!/bin/bash
function validate() {
  [[ ! -f .git/tempdir/check_docs.sh ]] && return 0
  .git/tempdir/check_docs.sh  && rm -f .git/tempdir/check_docs
}
