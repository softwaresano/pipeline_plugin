#!/bin/bash
# Validate makefile
function validate() {
  make -n -f "${file_name:?}" 2>/dev/stdout
}
