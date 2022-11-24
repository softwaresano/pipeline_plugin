#!/bin/bash
# Validate ruby
function validate(){
  if [[ -x .git/tempdir/rb_hook.sh ]]; then
     .git/tempdir/rb_hook.sh "${file_name:?}"
     return $?
  fi
  command -v rubocop  >/dev/null || return 126
  rubocop "${file_name:?}"
}
