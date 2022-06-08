#!/bin/bash
# Validate typescript
function validate(){
  source "$validator_dir"/cxx_validator.sh
  cpp_validate
}
