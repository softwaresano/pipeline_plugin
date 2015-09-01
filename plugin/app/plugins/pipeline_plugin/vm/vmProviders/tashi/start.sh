#!/bin/bash
source /home/develenv/bin/setEnv.sh
source `dirname $(readlink -f $0)`/../../tools/vmCommons.sh
source `dirname $(readlink -f $0)`/vmCommons.sh

[[ $(isUp $2) == "true" ]] && _log "[WARN] $2 is already in use" && exit 0

$SSH_COMMAND "tashi createVm $*"
errorCode=$?
[[ $errorCode != 0 ]] && exit $errorCode
_log "[INFO] $2 created"
_log "[INFO] Waiting access to $2"
sleep $WAITING_COUNTER
counter=10
[[ $(isUp $2) == "false" ]] && _log "[ERROR] Unable access to $2$DOMAIN" && exit 1

