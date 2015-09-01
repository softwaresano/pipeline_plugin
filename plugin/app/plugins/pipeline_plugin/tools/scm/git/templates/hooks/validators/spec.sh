#!/bin/bash
# Validate specfile
function is_rpm_spec_file(){
  [[ "$(grep '^%files' $file_name|wc -l)" == "1" ]] && return 0
}
function validate(){
  local exit_code=0
  is_rpm_spec_file || return 126
  which rpmlint2 2>/dev/null >/dev/null || return 126
  rm rpmlint.log
  rpmlint $file_name|tee -a rpmlint.log
  #filter by number errors. RPM_SOURCE_DIR isnot a error
  exit_code=$(cat rpmlint.log|grep -v "E: use-of-RPM_SOURCE_DIR$"|grep ":"|cut -d':' -f2-|grep -v " W:"|wc -l)
  rm rpmlint.log
  #string to integer
  return $(($exit_code))
}