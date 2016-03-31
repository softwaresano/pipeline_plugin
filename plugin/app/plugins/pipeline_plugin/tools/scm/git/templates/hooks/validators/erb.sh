#!/bin/bash
# Validate sh
function validate(){
  erb -P -x -T '-' $file_name | ruby -c 2>/dev/null 1>/dev/null
}
