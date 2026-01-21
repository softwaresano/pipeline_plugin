#!/bin/bash

function hello() {
  VALUE=5
  if [[ $VALUE -eq '5' ]]; then
    echo "Hello"
  else
    echo "Goodbye"
  fi
}
