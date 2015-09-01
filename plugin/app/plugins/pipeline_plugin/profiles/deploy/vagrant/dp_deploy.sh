#!/bin/bash
[ -z "DP_HOME" ] && echo "[Error] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[vagrant] deploy type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

cd /vagrant/manifests && \
   sudo puppet apply --verbose --modulepath \
   '/etc/puppet/modules:/vagrant/modules:/vagrant/shared/modules:/vagrant/core/modules' site.pp --detailed-exitcodes
