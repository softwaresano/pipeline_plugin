#!/bin/bash
nameVm=$(echo `basename $0`|sed s:"\..*":"":g)
command="start"
if [ $# == "1" ]; then
   command=$1
fi
if [ "$command" == "stop" ]; then
   commandParameters=$nameVm
else
   commandParameters="--name $nameVm --cores 1 --memory 512 --disks x86_64-centos-6.2-base.qcow2 --nics 1003"
fi

/home/develenv/app/plugins/pipeline_plugin/vm/vmProviders/tashi/${command}.sh $commandParameters
