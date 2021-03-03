#!/bin/bash
[[ -n "${SCM_URL}" ]] && echo "${SCM_URL}" || git config --get remote.origin.url
