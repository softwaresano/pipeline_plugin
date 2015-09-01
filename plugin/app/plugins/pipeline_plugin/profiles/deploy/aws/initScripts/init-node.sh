#!/bin/bash

echo 0 > /selinux/enforce
yum update-minimal
rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
yum updateinfo -y
yum install puppet -y

echo "@NODE_TAG-aws-@USER-$(hostname)" > /etc/hostname
hostname $(cat /etc/hostname) >> /var/log/syslog

echo "@PM_IP puppet @PM_INTERNAL_DN" >> /etc/hosts
echo "$(ifconfig eth0 | grep inet.addr| awk '{print $2}' | cut -d: -f2) $(cat /etc/hostname)" >> /etc/hosts

cat << EOF >> /etc/puppet/puppet.conf

server = @PM_INTERNAL_DN
splaylimit = 60
runinterval = 200
EOF


sed -i s/START=no/START=yes/g /etc/default/puppet >> /var/log/syslog
service puppet start >> /var/log/syslog

