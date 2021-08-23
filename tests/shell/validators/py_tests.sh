#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/py.sh"

PYTHON_OK="tests/shell/validators/fixtures/python_ok.py"
PYTHON_KO="tests/shell/validators/fixtures/python_ko.py"

function test_py_ok() {
  file_name="$PYTHON_OK" validate
  ${_ASSERT_TRUE_} $?
}

function test_py_ko() {
  file_name="$PYTHON_KO" validate
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
