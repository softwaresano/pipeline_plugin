#!/bin/bash
# Validate ruby
function validate(){
  ruby -c $file_name 1>/dev/null
}
