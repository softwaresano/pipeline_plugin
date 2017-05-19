#!/bin/bash
# Validate puppet
function validate(){
  source $validator_dir/non_ascii.sh
  is_ascii || return 1
  which puppet 2>/dev/null >/dev/null || return 126
  puppet parser --parser=future validate $file_name 2>/dev/stdout || return 1
  which puppet-lint 2>/dev/null >/dev/null || return 0
  puppet-lint --no-autoloader_layout-check --no-puppet_url_without_modules-check --no-80chars-check --fix --with-filename "$file_name" 2>/dev/stdout
}
