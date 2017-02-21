#!/bin/bash

apt-get install -y software-properties-common
add-apt-repository -y --remove cloud-archive:kilo
add-apt-repository -y cloud-archive:liberty
apt-get update
apt-get install -y crudini

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y nova-compute sysfsutils
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y neutron-plugin-linuxbridge-agent conntrack

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y

crudini --set /etc/nova/nova.conf upgrade_levels compute 4.5

service neutron-plugin-linuxbridge-agent restart
service nova-compute restart
