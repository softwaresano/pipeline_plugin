#!/bin/bash

function is_ascii(){
  LANG=C grep -n --color='auto' '[^ -~]\+' $file_name && echo "NON-ASCII characters" && return 1
}
