#!/bin/bash
function git() {
  if [[ -n ${COMPONENT_HOME} ]]; then
    (cd "${COMPONENT_HOME:?}" && /usr/bin/git "$@")
  else
    /usr/bin/git "$@"
  fi

}
