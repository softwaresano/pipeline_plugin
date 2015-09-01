#!/bin/bash
new_languages=$(find "$DP_HOME/profiles/metrics/tools/languages" -name "cloc.sh")
IFS=$'\n'
tmp_file="target/reports/sloccount.sc.tmp"
rm -rf target/reports/sloccount.sc.tmp
for language in $new_languages; do
    results=$($language)
    for result in $results; do
        n_lines=$(echo $result|cut -d'|' -f1)
        type_file=$(echo $result|cut -d'|' -f2)
        file=$(echo $result|cut -d'|' -f3)
        echo "$n_lines	$type_file	$(dirname $file|sed s:"^.$":"":g|cut -d'/' -f2)	$file"
    done;
done;
