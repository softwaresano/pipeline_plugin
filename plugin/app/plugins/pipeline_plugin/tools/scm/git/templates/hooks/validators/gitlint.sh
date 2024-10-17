#!/bin/bash
function validate() {
  if command -v codespell &>/dev/null; then
    echo "${commit_message}"|codespell - || return 1	
  fi
  echo "$commit_message" | PYTHONUSERBASE=/opt/p2pcdn/var/lib/gitlint/ \
    /opt/p2pcdn/var/lib/gitlint/bin/gitlint \
    --config "${CDN_BUILD_LIB:-/opt/p2pcdn/var/lib/build}"/linters/gitlint.ini
}
