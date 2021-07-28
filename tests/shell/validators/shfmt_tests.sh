#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/shfmt.sh"

SHFMT_OK="tests/shell/validators/fixtures/shfmt_ok.sh"
SHFMT_KO="tests/shell/validators/fixtures/shfmt_ko.sh"

function test_shfmt_ok() {
  validate "$SHFMT_OK"
  ${_ASSERT_TRUE_} $?
}

function test_shfmt_ko() {
  validate "$SHFMT_KO"
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
