#!/bin/bash
# Validate javascript
function validate(){
  source "$validator_dir"/javascript_validator.sh
  js_validate
}