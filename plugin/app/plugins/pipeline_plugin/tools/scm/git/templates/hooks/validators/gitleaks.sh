#!/bin/bash

# Validate markdown
function validate() {
  command -v gitleaks >/dev/null || return 0
  gitleaks protect --verbose --redact --staged "${file_name:?}"
}
