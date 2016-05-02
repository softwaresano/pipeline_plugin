#!/bin/bash
# Validate bash
function validate_yamlint(){
  local syntax_error=$(curl --form authenticity_token="jTaXNkfys1RqMl0FixPfBqBObw1FV5GKZVvujU0uM="  --form yaml="$(cat $file_name)" --form commit="Go" http://www.yamllint.com/ 2>/dev/null|grep "syntax error")
  echo $syntax_error
  [[ "$syntax_error" == "" ]] && return 0 || return 1
}
function validate_ruby(){
  ruby -e "require 'yaml';puts YAML.load_file('$file_name')"
  if [[ $? != 0 ]]; then
    return 1
  fi
  which yamllint 2>/dev/null >/dev/null || return 0
  yamllint -c $DP_HOME/tools/scm/git/templates/hooks/validators/yamllint  "$file_name" 2>/dev/stdout
}

function validate(){
  which ruby 2>/dev/null
  if [ $? == 0 ]; then
    validate_ruby
  else
    validate_yamlint
  fi
}
