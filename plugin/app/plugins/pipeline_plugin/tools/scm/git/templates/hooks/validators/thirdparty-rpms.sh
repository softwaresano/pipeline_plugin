#!/bin/bash
# Validate bash
function validate(){
  sed -i '/^### Devel packages$/,$d' thirdparty-rpms.txt
  sed -i '$d' thirdparty-rpms.txt
  grep -q "### Devel packages" "${file_name:?}" && 
    echo "thirdparty-rpms.txt  modified automatically" && return 1
  return 0
}
