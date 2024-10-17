#!/bin/bash

# Validate prettier
function validate() {
  command -v codespell &>/dev/null || return 126
  codespell -S Pipfile.lock,package-lock.json,Gemfile.lock "${file_name:?}" || return 1
}
