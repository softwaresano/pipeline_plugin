function validate() {
  local gitlint_temp
  local commit_message
  commit_message=$1
  gitlint_temp=$(mktemp -u /tmp/gitlint.XXXX)
  echo "$commit_message"| PYTHONUSERBASE=/opt/p2pcdn/var/lib/gitlint/ \
    /opt/p2pcdn/var/lib/gitlint/bin/gitlint \
    --config  "${CDN_BUILD_LIB}"/linters/gitlint.ini &> "${gitlint_temp}"
  retval_gitlint=$?
  if [[ "$retval_gitlint" != 0 ]]; then
    dp_log.sh "[ERROR] [KO] [gitlint] Bad commit message"
    cat "${gitlint_temp}"
  fi
  rm -f "${gitlint_temp}"
  return "${retval_gitlint}"
}