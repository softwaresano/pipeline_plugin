#!/bin/bash

source "plugin/app/plugins/pipeline_plugin/tools/scm/git/templates/hooks/validators/sh.sh"

SH_OK="tests/shell/validators/fixtures/shell_ok.sh"
SH_KO="tests/shell/validators/fixtures/shell_bad_commad.sh"

function test_sh_ok() {
  file_name="$SH_OK" validate
  ${_ASSERT_TRUE_} $?
}

function test_sh_ko() {
  file_name="$SH_KO" validate
  ${_ASSERT_FALSE_} $?
}

source "/opt/p2pcdn/var/lib/shUnit2/shunit2"
