#!/bin/bash
function validate() {
  echo "$commit_message" | PYTHONUSERBASE=/opt/p2pcdn/var/lib/gitlint/ \
    /opt/p2pcdn/var/lib/gitlint/bin/gitlint \
    --config "${CDN_BUILD_LIB}"/linters/gitlint.ini
}
