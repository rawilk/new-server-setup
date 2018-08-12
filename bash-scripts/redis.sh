#!/bin/bash

# Update server
sudo yum -y update

# Install Redis
sudo yum -y install redis

# Start redis
sudo systemctl start redis
sudo systemctl enable redis

# Configure redis
sudo sed -i -e "s/appendonly no/appendonly yes/" /etc/redis.conf

# Restart redis
sudo systemctl restart redis

# Tuning
sudo sysctl vm.overcommit_memory=1
sudo echo vm.overcommit_memory=1 >> /etc/sysctl.conf