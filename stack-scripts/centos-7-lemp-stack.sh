#!/bin/bash
#
# Author Randall Wilk <randall@randallwilk.com>
#
#
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
# The hostname for hte new Linode
LINODE_HOST_NAME=""
#
# The new Linode's fully qualified domain name
FQDN=""
#
# The server's timezone
TIMEZONE="America/Chicago"
#
# The dedicated shell user we will create
SHELL_USER_NAME=""
SHELL_USER_PASSWORD=""
#
# The dedicated ftp user we will create
FTP_USER_NAME=""
FTP_USER_PASSWORD=""
#
# The SSH port the new linode will use
SSH_PORT=22
#

# Redirect output of this script to our logfile
exec &> /root/stackscript.log

# This sets the variable $IPADDR to the IP address the new Linode receives
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# Set timezone
echo "Setting timezone to: $TIMEZONE"
timedatectl set-timezone "$TIMEZONE"

# Install NTP date sync
yum -y install ntp
systemctl start ntpd
systemctl enable ntpd
echo "...done"

# This section sets the host name.
echo $LINODE_HOST_NAME > /etc/hostname
hostname -F /etc/hostname

# This section sets the fully qualified domain name (FDQN) in the hosts file
echo $IPADDR $FQDN $LINODE_HOST_NAME >> /etc/hosts

# Create dedicated shell user
echo "Creating shell user: $SHELL_USER_NAME"
useradd $SHELL_USER_NAME && echo $SHELL_USER_PASSWORD | passwd $SHELL_USER_PASSWORD --stdin
usermod -aG wheel $SHELL_USER_NAME
echo "Done creating shell user"

# Disable root over ssh
echo "Disabling root over ssh"
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
echo "Restarting sshd..."
systemctl restart sshd
echo "...done"

# Remove unneeded services
echo "Removing unneeded services..."
yum remove -y avahi chrony
echo "...done"

# Initial yum installs
yum -y update
yum -y install epel-release
yum -y update

# Set up automatic updates
echo "Setting up automatic updates"
yum -y install yum-cron
sed -i -e "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
echo "...done"

# Enable the firewall
echo "Setting up firewalld..."
systemctl start firewalld
systemctl enable firewalld
# Use public zone
firewall-cmd --set-default-zone=public
firewall-cmd --zone=public --add-interface=eth0
firewall-cmd --reload
echo "...done"

# Install composer
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install Node and NPM
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
yum -y install nodejs
npm install npm@latest -g

# Script has finished
ecoh "#### Installation Complete! ####"