#!/bin/bash
SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
WAITING_COUNTER=10
function isUp(){
   local packageReceived=0;
   local counter=10
   until [ "$packageReceived" != "0" -a "$counter" != "0" ]; do
      packageReceived=$(LANG=C;ping -c 1 -W 5 $1$DOMAIN|grep "received,"|cut -d',' -f2|awk '{print $1}')
      counter=`expr $counter - 1`
      [[ "$packageReceived" == "" ]] && echo "false" && return 1
   done
   if [ "$packageReceived" == "0" ]; then
      echo "false"
      return 1
   fi
   echo "true"
}

