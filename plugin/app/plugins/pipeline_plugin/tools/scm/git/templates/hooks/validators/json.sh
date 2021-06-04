#!/bin/bash
# Validate json
function validate(){
  command -v json_verify >/dev/null || return 0
  json_verify < "${FILE_NAME}"
}
