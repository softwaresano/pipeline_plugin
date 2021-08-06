#!/bin/bash

# Validate pem
function validate() {
  command -v openssl >/dev/null || return 126
  openssl x509 -checkend 1 -in "${file_name}" -noout 2>/dev/stdout
}
