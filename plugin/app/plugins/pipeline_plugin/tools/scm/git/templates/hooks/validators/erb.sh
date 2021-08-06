#!/bin/bash

# Validate sh
function validate() {
  command -v erb >/dev/null || return 126
  erb -P -x -T '-' "$file_name" | ruby -c 1>/dev/null
}
