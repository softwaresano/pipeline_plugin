#!/bin/bash
# Validate sh
function validate(){
  which erb 2>/dev/null >/dev/null || return 126
  erb -P -x -T '-' $file_name | ruby -c 1>/dev/null
}
