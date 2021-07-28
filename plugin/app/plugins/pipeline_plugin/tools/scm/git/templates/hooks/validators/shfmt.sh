#!/bin/bash

# Validate shell formater
function validate() {
  FILENAME="$1"
  if ! shfmt -d -s -i 2 "$FILENAME"; then
    dp_log.sh "[INFO] Run shfmt -i 2 -w -s $FILENAME to fix it"
    return 1
  fi
}
