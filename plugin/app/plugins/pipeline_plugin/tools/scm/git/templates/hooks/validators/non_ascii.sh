#!/bin/bash

function is_ascii(){
  LC_CTYPE=C grep -n --color='auto' '[^[:print:]]' $file_name && echo "NON-ASCII characters" && return 1
  return 0
}
