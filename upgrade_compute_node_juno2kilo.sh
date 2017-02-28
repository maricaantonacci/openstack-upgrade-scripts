#!/bin/bash
#
# Upgrade OpenStack Compute Node from Juno to Kilo
#

#clean 
apt-get -y autoremove

echo "Upgrade OpenStack Compute Node from Juno to Kilo"

# Create backup directories
echo "Creating backup directories..."
for i in nova neutron ceilometer; \
   do mkdir -p /var/lib/backups/openstack/$i-juno; \
   done

# Backup configuration files  
echo "Backing-up configuration files..."
for i in nova neutron ceilometer; \
   do cp -r /etc/$i/* /var/lib/backups/openstack/$i-juno/; \
   done

## Ad-hoc commands for our infra
sed -i '/puppetlabs/d' /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E84AC2C0460F3994
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7F438280EF8D349F
####
# Stop OpenStack services 
echo "Stopping OpenStack service..."
service nova-compute stop
service neutron-plugin-linuxbridge-agent stop
service ceilometer-agent-compute stop

# Install Kilo repository
echo "Updating APT repository..."
rm /etc/apt/sources.list.d/ubuntu-cloud-archive.list 
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y cloud-archive:kilo
apt-get update
apt-get install -y crudini

echo "Upgrade nova and neutron packages"
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y 
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install --only-upgrade -y nova-compute sysfsutils 
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install --only-upgrade -y neutron-plugin-linuxbridge-agent conntrack 


# Update nova.conf
echo "Setting Nova compute level to Juno"
crudini --set /etc/nova/nova.conf upgrade_levels compute juno


# Update neutron.conf
echo "Updating neutron.conf"
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit

# Update api-paste.ini
echo "Updating api-paste.ini"
crudini --set /etc/neutron/api-paste.ini filter:request_id paste.filter_factory oslo.middleware:RequestId.factory
crudini --set /etc/neutron/api-paste.ini filter:catch_errors paste.filter_factory oslo.middleware:CatchErrors.factory

echo "Upgrading system packages..."
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
#apt-get autoremove -y
#

# Restart service
echo "Restarting Nova and Neutron services..."
service nova-compute restart
service neutron-plugin-linuxbridge-agent restart

# Upgrade CEILOMETER service
echo "Upgrading CEILOMETER service..."
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y ceilometer-agent-compute ceilometer-common python-ceilometer python-ceilometerclient

# Restart service 
#echo "Restarting Ceilometer service..."
#service ceilometer-agent-compute restart

echo "End of COMPUTE NODE update process!"
