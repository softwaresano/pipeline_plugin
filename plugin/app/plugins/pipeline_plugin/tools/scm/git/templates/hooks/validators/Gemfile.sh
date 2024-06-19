#!/bin/bash
# Gemfile tracked by git and newer than Gemfile.lock
function validate(){
  source "$validator_dir"/file_lock_validator.sh
  file_lock_validate "Gemfile.lock" || return 1
}
