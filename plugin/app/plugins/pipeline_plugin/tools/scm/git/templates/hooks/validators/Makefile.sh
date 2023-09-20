#!/bin/bash
# Validate makefile
function validate() {
  if ! grep "CDN_BUILD_LIB" Makefile; then 
     make -n -f $file_name 2>/dev/stdout
  fi
}
