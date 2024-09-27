#!/bin/bash

function hello_wrong(){
  local not_in_use='value not in use'
  VALUE=6
  if [[ $VALUE -eq '5' ]]; then
    echo "Hello"
  else
    echo "Goodbye"
  fi
}
