#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/shellcheck.sh"

SHELLCHECK_OK="tests/shell/validators/fixtures/shell_ok.sh"
SHELLCHECK_KO="tests/shell/validators/fixtures/shell_ko.sh"

function test_shellcheck_ok() {
  file_name="$SHELLCHECK_OK" validate 
  ${_ASSERT_TRUE_} $?
}

function test_shellcheck_ko() {
  file_name="$SHELLCHECK_KO" validate
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
