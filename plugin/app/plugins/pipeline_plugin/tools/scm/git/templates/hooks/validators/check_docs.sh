#!/bin/bash
function validate() {
  [[ ! -f .git/tempdir/check_docs ]] && return 0
  ${CDN_BUILD_LIB:?}/bin/check_docs && rm -f .git/tempdir/check_docs
}
