#!/bin/bash
# Validate bash
function validate(){
  grep -q "### Devel packages" "${file_name:?}" && 
    echo "thirdparty-rpms.txt  modified automatically" && return 1
  return 0
}
