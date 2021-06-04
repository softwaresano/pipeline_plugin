#!/bin/bash

# Validate sh
function validate(){
  command -v erb >/dev/null || return 126
  erb -P -x -T '-' "$FILE_NAME" | ruby -c 1>/dev/null
}
