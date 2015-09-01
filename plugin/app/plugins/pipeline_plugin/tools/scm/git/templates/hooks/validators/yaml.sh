#!/bin/bash
# Validate bash
function validate(){
  local syntax_error=$(curl --form authenticity_token="jTaXNkfys1RqMl0FixPfBqBObw1FV5GKZVvujU0uM="  --form yaml="$(cat $file_name)" --form commit="Go" http://www.yamllint.com/ 2>/dev/null|grep "syntax error")
  echo $syntax_error
  [[ "$syntax_error" == "" ]] && return 0 || return 1
}
