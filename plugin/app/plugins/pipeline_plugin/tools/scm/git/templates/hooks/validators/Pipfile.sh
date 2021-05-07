#!/bin/bash
# Pipfile tracked by git and newer than Pipfile.lock
function validate(){
  source "$validator_dir"/file_lock_validator.sh
  file_lock_validate "Pipfile.lock"
}
