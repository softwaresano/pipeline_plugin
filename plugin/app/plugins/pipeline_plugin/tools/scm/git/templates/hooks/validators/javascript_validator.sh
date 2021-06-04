#!/bin/bash
# Validate typescript
function js_validate(){
  if [[ -f "${CDN_BUILD_LIB}" ]]; then
    PATH=/opt/p2pcdn/angular-cli/bin/:$PATH eslint -c "${CDN_BUILD_LIB}"/angular/.eslintrc.json "${file_name:?}"
  else
    command -v eslint >/dev/null || return 0
    eslint "${file_name:?}"
  fi
}
