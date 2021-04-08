#!/bin/bash
# Validate json
function validate(){
  which json_verify 2>/dev/null >/dev/null || return 0
  json_verify < "${file_name}"
}
