#!/bin/bash
source /home/develenv/bin/setEnv.sh
source `dirname $(readlink -f $0)`/../../tools/vmCommons.sh
$SSH_COMMAND "vboxmanage controlvm --instance $1 poweroff"

