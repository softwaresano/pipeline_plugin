#!/bin/bash

# Validate puppet
function validate() {
  [[ -f /opt/puppetlabs/bin/puppet ]] || return 126
  #shellcheck source=./plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/pre-commit
  /opt/puppetlabs/bin/puppet parser validate "$file_name" 2>/dev/stdout || return 1
  command -v puppet-lint >/dev/null || return 126
  if puppet-lint --no-autoloader_layout-check --no-puppet_url_without_modules-check --no-80chars-check --with-filename "$file_name"|grep "\- WARNING: "; then
    dp_log.sh "[INFO] puppet-lint --no-autoloader_layout-check --no-puppet_url_without_modules-check --no-80chars-check --fix --with-filename "$file_name""
  return 1
  fi
}
