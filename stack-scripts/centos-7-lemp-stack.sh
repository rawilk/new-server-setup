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

echo "Starting install"

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
echo "Setting hostname to: $LINODE_HOST_NAME"
echo $LINODE_HOST_NAME > /etc/hostname
hostname -F /etc/hostname

# This section sets the fully qualified domain name (FDQN) in the hosts file
echo $IPADDR $FQDN $LINODE_HOST_NAME >> /etc/hosts
echo "...done"

# Create dedicated shell user
echo "Creating shell user: $SHELL_USER_NAME"
useradd $SHELL_USER_NAME && echo $SHELL_USER_PASSWORD | passwd $SHELL_USER_PASSWORD --stdin
usermod -aG wheel $SHELL_USER_NAME
echo "...done"

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
echo "Updating yum"
yum -y update
yum -y install epel-release
yum -y update
echo "...done"

# Set up automatic updates
echo "Setting up automatic updates"
yum -y install yum-cron
sed -i -e "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
echo "...done"

# Setup fail2ban
echo "Setting up fail2ban"
yum -y install fail2ban
cd /etc/fail2ban
cp fail2ban.conf fail2ban.local
cp jail.conf jail.local
sed -i -e "s/backend = auto/backend = systemd/" /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
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

# Setup FTP
echo "Installing vsftpd"
yum -y install vsftpd
echo "...done"

# Create FTP user
echo "Creating FTP user: $FTP_USER_NAME"
useradd $FTP_USER_NAME && echo $FTP_USER_PASSWORD | passwd $FTP_USER_PASSWORD --stdin
echo "...done"

# Update firewall rules for ftp
echo "Configuring firewall for FTP"
firewall-cmd --add-port=20/tcp --zone=public --permanent
firewall-cmd --add-port=20/udp --zone=public --permanent
firewall-cmd --add-port=21/tcp --zone=public --permanent
firewall-cmd --add-port=21/udp --zone=public --permanent
firewall-cmd --add-port=40000-40100/tcp --zone=public --permanent
firewall-cmd --add-port=40000-40100/udp --zone=public --permanent
firewall-cmd --reload
echo "...done"

# Enable vsftpd
echo "Enabling vsftpd"
systemctl start vsftpd
systemctl enable vsftpd
echo "...done"

# Install nginx and php
echo "Installing PHP and Nginx"
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install nginx php72w-fpm php72w-bcmath php72w-gd php72w-mbstring php72w-xmlrpc php72w-mysql php72w-pdo php72w-pecl-imagick php72w-xml
echo "...done"

# Allow app through firewall
firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=443/tcp --zone=public --permanent
firewall-cmd --reload

# Install composer
echo "Installing composer"
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo "...done"

# Install Node and NPM
echo "Installing node and npm"
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
yum -y install nodejs
npm install npm@latest -g
echo "...done"

# Script has finished
echo "#### Installation Complete! ####"