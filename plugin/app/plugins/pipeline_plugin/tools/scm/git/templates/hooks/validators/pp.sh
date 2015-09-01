#!/bin/bash
# Validate puppet
function validate(){
  which puppet 2>/dev/null >/dev/null || return 126
  puppet parser validate $file_name 2>/dev/stdout
}
