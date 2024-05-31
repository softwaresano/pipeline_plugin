#!/bin/bash

# Validate puppet
function validate() {
  [[ -f /opt/puppetlabs/bin/puppet ]] || return 126
  #shellcheck source=./plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/pre-commit
  /opt/puppetlabs/bin/puppet parser validate "${file_name:?}" 2>/dev/stdout || return 1
}
