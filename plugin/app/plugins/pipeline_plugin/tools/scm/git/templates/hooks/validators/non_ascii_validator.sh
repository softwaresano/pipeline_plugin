#!/bin/bash

function encoding_validate(){
  LC_CTYPE=C grep -n --color='auto' '[^[:print:]]' $file_name && echo "NON-ASCII characters" && return 1
  return 0
}
