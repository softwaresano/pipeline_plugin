#!/bin/bash
# Validate python_file
function validate(){
  python2 -c "import py_compile;py_compile.compile('$file_name',doraise='True')"
}
