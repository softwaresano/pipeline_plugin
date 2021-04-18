#!/bin/bash
# Validate typescript
function validate(){
  source "$validator_dir"/javascript_validator.sh
  js_validate
}
