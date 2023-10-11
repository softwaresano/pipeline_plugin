#!/bin/bash

# Validate markdown
function validate() {
  command -v mdl >/dev/null || return 0
  mdl "${file_name:?}"
}
