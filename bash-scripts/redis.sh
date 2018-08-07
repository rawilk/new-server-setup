#!/bin/bash

# Update server
yum -y update

# Install Redis
yum -y install redis

# Start redis
systemctl start redis
systemctl enable redis

# Configure redis
sed -i -e "s/appendonly no/appendonly yes/" /etc/redis.conf

# Restart redis
systemctl restart redis

# Tuning
sysctl vm.overcommit_memory=1
echo vm.overcommit_memory=1 >> /etc/sysctl.conf