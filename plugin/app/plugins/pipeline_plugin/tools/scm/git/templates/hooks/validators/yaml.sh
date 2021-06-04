#!/bin/bash
# Validate bash
function validate_yamlint(){
  cat_file=$(cat "$FILE_NAME")
  local syntax_error
  syntax_error=$(curl --form authenticity_token="jTaXNkfys1RqMl0FixPfBqBObw1FV5GKZVvujU0uM="  --form yaml="$cat_file" --form commit="Go" http://www.yamllint.com/ 2>/dev/null|grep "syntax error")
  echo "$syntax_error"
  [[ "$syntax_error" == "" ]] && return 0 || return 1
}
function validate_ruby(){
  if [[ ! $(ruby -e "require 'yaml';puts YAML.load_file('$FILE_NAME')") ]]; then
    return 1
  fi
  command -v yamllint >/dev/null || return 0
  yamllint -c "$DP_HOME/tools/scm/git/templates/hooks/validators/yamllint" "$FILE_NAME" 2>/dev/stdout
}

function validate(){
  if [[ $(command -v ruby) ]]; then
    validate_ruby
  else
    validate_yamlint
  fi
}
