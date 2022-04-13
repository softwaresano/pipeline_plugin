#!/bin/bash
# Validate ruby
function validate(){
  ruby -c $file_name 1>/dev/null || return 1
  command -v rubocop  >/dev/null || return 126
  rubocop "${file_name:?}"
}
