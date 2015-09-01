#!/bin/bash

# Download the Puppet configuration for the Puppet Master
# and set it up
tar xzvf puppetMasterCode.tgz
# To be sure not to have any codification problems
find modules -type f -exec dos2unix {} \;
find shared/modules -type f -exec dos2unix {} \;
find core/modules -type f -exec dos2unix {} \;

cp -R manifests/* /etc/puppet/manifests
cp -R modules /etc/puppet/
[ -d core ] && cp -R core/modules/* /etc/puppet/modules
[ -d shared ] && cp -R shared/modules/* /etc/puppet/modules
mv /home/ec2-user/localSourceCode.tar /etc/puppet/files

# An evil imp changes this permissions randomly, ruining SSH access
chmod g-w /home/ec2-user
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

