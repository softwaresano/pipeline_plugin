#!/bin/bash
# Validate Jenkinsfile
source $(python3 -c 'import os,sys;print (os.path.realpath(sys.argv[1]))' $0/..)/validators/groovy.sh
