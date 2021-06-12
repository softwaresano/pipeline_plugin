function validate() {
  local gitlint_temp
  local commit_message
  commit_message=$1
  gitlint_temp=$(echo "$commit_message"| PYTHONUSERBASE=/opt/p2pcdn/var/lib/gitlint/ \
    /opt/p2pcdn/var/lib/gitlint/bin/gitlint \
    --config  "${CDN_BUILD_LIB}"/linters/gitlint.ini &>/dev/stdout)
  retval_gitlint=$?
  if [[ "$retval_gitlint" != 0 ]]; then
    dp_log.sh "[ERROR] [KO] [gitlint] Bad commit message"
    echo "${gitlint_temp}"
  fi
  return "${retval_gitlint}"
}