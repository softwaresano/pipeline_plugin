#!/bin/bash
# Validate makefile
function validate(){
   grep "CDN_BUILD_LIB" Makefile || return 0
   make -n
}
