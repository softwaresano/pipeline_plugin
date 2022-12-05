#!/bin/bash
# Validate bash
function validate() {
  if grep -Eq "^### Devel packages$" "${file_name:?}"; then
    sed -i '/^### Devel packages$/,$d' "${file_name:?}" || return 1
    sed -i '$d' "${file_name:?}"
    git add "${file_name:?}"
  fi
}
