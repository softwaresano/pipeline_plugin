#!/bin/bash
source /home/develenv/bin/setEnv.sh
source `dirname $(readlink -f $0)`/vmCommons.sh
SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SSH_COMMAND="ssh $SSH_OPTIONS carlosg@hadoop.bigdata.hi.inet"
$SSH_COMMAND "tashi destroyVm --instance $1"

