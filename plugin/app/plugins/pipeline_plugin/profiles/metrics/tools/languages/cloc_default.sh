#!/bin/bash
files=$(find . -name "*.$1"|grep -v target|grep -v \.venv|grep -v \.svn)
IFS=$'\n'
for file in $files; do
    n_lines=$(cat $file |tr -d ' \t'|grep -v '^$'|grep -v "^#"|wc -l)
    echo "$n_lines|$2|$file" 
#   echo "$n_lines  Rpm specfile    $(dirname $file|sed s:"^.$":"":g|cut -d'/' -f2) $file"
done;
unset IFS