#!/bin/bash
# Validate bash
function validate(){
  sed -i '/^### Devel packages$/,$d' "${file_name:?}" || return 1
  sed -i '$d' "${file_name:?}"
}
