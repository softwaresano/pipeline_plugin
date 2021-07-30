#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/shfmt.sh"

SHFMT_OK="tests/shell/validators/fixtures/shell_ok.sh"
SHFMT_KO="tests/shell/validators/fixtures/shell_ko.sh"

function test_shfmt_ok() {
  file_name="$SHFMT_OK" validate
    ${_ASSERT_TRUE_} $?
}

function test_shfmt_ko() {
  file_name="$SHFMT_KO" validate
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
