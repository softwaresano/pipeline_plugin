#!/bin/bash
# Validate sh
function validate(){
  sh -n $file_name  2>/dev/stdout && shellcheck $file_name 2>/dev/stdout
}
