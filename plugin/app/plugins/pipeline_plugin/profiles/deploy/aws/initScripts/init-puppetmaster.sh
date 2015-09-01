#!/bin/bash

# Prepare some folders that will be needed by the deplyment script
mkdir /etc/puppet
mkdir /etc/puppet/files

# Install PuppetDB to store Node fact information
yum update-minimal
rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
yum updateinfo -y
yum install puppet puppetdb puppet-server puppetdb-terminus dos2unix -y

# Change the permissions of the puppet folder to enable code-updating
chmod 777 /etc/puppet/files
chmod 777 /etc/puppet/modules
chmod 777 /etc/puppet/manifests

cat << EOF > /etc/puppet/puppetdb.conf
[main]
server = $(hostname -f)
port = 8081
EOF

cat << EOF >> /etc/puppet/puppet.conf
storeconfigs = true
storeconfigs_backend = puppetdb
reports = store,puppetdb
EOF

cat << EOF > /etc/puppet/routes.yaml
---
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOF

cat << EOF > /etc/puppet/hiera.yaml
:backends:
  - yaml
:yaml:
  :datadir:  /var/lib/puppet/hieradata/
:hierarchy:
  - nodes/%{::clientcert}
  - common
EOF

cat << EOF >> /etc/puppet/fileserver.conf
[extra_files]
path /etc/puppet/files
allow *
EOF

mkdir /etc/puppet/files
mkdir /var/lib/puppet/hieradata
echo "*" > /etc/puppet/autosign.conf

# Download the Puppet configuration for the Puppet Master
service puppetdb restart
service puppetmaster restart

# Open the rules in the firewall
iptables -I INPUT 4 -i eth0 -p tcp --dport 8140 -j ACCEPT
iptables -I INPUT 4 -i eth0 -p tcp --dport 8081 -j ACCEPT

# Install a node script that will serialize the information to share 
# into the files repository of the Puppet Master
cd /root
wget http://nodejs.org/dist/v0.10.10/node-v0.10.10-linux-x64.tar.gz
tar xvfz node-v0.10.10-linux-x64.tar.gz

ln -s  /root/node-v0.10.10-linux-x64/bin/node /usr/bin/node
ln -s  /root/node-v0.10.10-linux-x64/bin/npm /usr/bin/npm

cd /home/ec2-user
npm install async >> /var/log/installation.log
npm install request@'2.1.0' >> /var/log/installation.log

echo -e "* * * * * root cd /home/ec2-user;/usr/bin/node /home/ec2-user/get-node-info.js >> /root/node-info.log\n" >> /etc/crontab
service cron restart

echo "Preparing SSL" >> /var/log/installation.log
/usr/sbin/puppetdb-ssl-setup >> /var/log/installation.log
echo "SSL Prepaired" >> /var/log/installation.log

service puppetdb restart

# An evil imp changes this permissions randomly, ruining SSH access
chmod g-w /home/ec2-user
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

