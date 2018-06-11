#!/bin/bash
# Validate bash
function validate(){
  bash -n $file_name 2>/dev/stdout && shellcheck -s bash $file_name 2>/dev/stdout
}
