#!/bin/bash
# Validate puppet
function validate(){
  # shellcheck source=./plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/non_ascii.sh
  source "$VALIDATOR_DIR/non_ascii.sh"
  [[ -f /opt/puppetlabs/bin/puppet ]] || return 126
  /opt/puppetlabs/bin/puppet parser validate "$FILE_NAME" 2>/dev/stdout || return 1
  command -v puppet-lint >/dev/null || return 0
  puppet-lint --no-autoloader_layout-check --no-puppet_url_without_modules-check --no-80chars-check --fix --with-filename "$FILE_NAME" 2>/dev/stdout
}
