#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/Makefile.sh"

MAKEFILE_OK="tests/shell/validators/fixtures/Makefile_ok.sh"
MAKEFILE_KO="tests/shell/validators/fixtures/Makefile_ko.sh"

function test_py_ok() {
  file_name="$MAKEFILE_OK" validate
  ${_ASSERT_TRUE_} $?
}

function test_py_ko() {
  file_name="$MAKEFILE_KO" validate
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
