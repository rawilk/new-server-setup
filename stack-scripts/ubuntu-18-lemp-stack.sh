#!/bin/bash

# Define variables

#<UDF name="hostname" label="Enter main hostname for the new Linode server.">
#<UDF name="fqdn" label="Enter Server's Fully Qualified Domain Name (same as main hostname). Don't enter `www`">
#<UDF name="timezone" label="Server Timezone" default="America/Chicago" example="America/New_York">
#<UDF name="selinux" label="Enable SELinux?" oneOf="no,yes" default="no">
#<UDF name="ssh_pub_key" label="SSH pubkey (installed for root and shell user)" example="ssh-rsa ..." default="">
#<UDF name="password_login" label="Permit SSH Password Login" oneOf="no,yes" default="no">
#<UDF name="shell_user_name" label="Shell User Name">
#<UDF name="shell_user_password" label="Shell User Password">
#<UDF name="ssh_port" label="SSH Port" default="22">
#<UDF name="root_login" label="Permit Root SSH Login?" oneOf="no,yes" default="no">
#<UDF name="login_grace_time" label="SSH Login Grace Time" default="1m" example="2m">
#<UDF name="ftp_user_name" label="FTP User Name">
#<UDF name="ftp_user_password" label="FTP User Password">
#<UDF name="root_db_password" label="MariaDB Root Password">
#<UDF name="db_user_name" label="Database User Name">
#<UDF name="db_user_password" label="Database User Password">
#<UDF name="ssl" label="Install SSL Cert" oneOf="no,yes" default="yes">
#<UDF name="ssl_email" label="SSL Renewal and Security Notices Email" default="">

# This sets the variable $IPADDR to the IPv4 address the new Linode receives.
IPADDR=$(hostname -I | cut -f1 -d' ')

# This sets the variable $IPADDR6 to the IPv6 address the new Linode receives.
IPADDR6=$(hostname -I | cut -f2 -d' ')

# Redirect output of this script to our logfile
exec &> /root/stackscript.log

echo "#### Install Start ####"

# Update the system
apt update && apt upgrade -y

# Set the hostname
hostnamectl set-hostname $FQDN --static

# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts
echo $IPADDR6 $FQDN $HOSTNAME >> /etc/hosts

# Setup timezone
timedatectl set-timezone "$TIMEZONE"

# Create the sudo user account
adduser --disabled-password --gecos "" $SHELL_USER_NAME
echo "$SHELL_USER_NAME:$SHELL_USER_PASSWORD" | chpasswd
usermod -aG sudo $SHELL_USER_NAME

# Add user to allowed users in /etc/ssh/sshd_config
echo "AllowUsers $SHELL_USER_NAME" >> /etc/ssh/sshd_config

# Harden Server
if [ $ROOT_LOGIN = 'no' ]; then
    sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config
fi

sed -i -e "s/.*AddressFamily .*/AddressFamily inet/" /etc/ssh/sshd_config
sed -i -e "s/.*LoginGraceTime .*/LoginGraceTime $LOGIN_GRACE_TIME/" /etc/ssh/sshd_config
sed -i -e "s/.*ClientAliveInterval .*/ClientAliveInterval 600/" /etc/ssh/sshd_config
sed -i -e "s/.*ClientAliveCountMax .*/ClientAliveCountMax 0/" /etc/ssh/sshd_config

# Disable password login
if [ $PASSWORD_LOGIN = 'no' ] && [ $SSH_PUB_KEY != '' ]; then
    sed -i -e "s/.*PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
fi

# Setup ssh keys
if [ $SSH_PUB_KEY != '' ]; then
    mkdir -p /root/.ssh
    mkdir -p /home/$SHELL_USER_NAME/.ssh
    echo "$SSH_PUB_KEY" > /root/.ssh/authorized_keys
    echo "$SSH_PUB_KEY" > /home/$SHELL_USER_NAME/.ssh/authorized_keys
    chmod -R 700 /root/.ssh
    chmod -R 700 /home/${SHELL_USER_NAME}/.ssh
    chown -R ${SHELL_USER_NAME}:${SHELL_USER_NAME} /home/${SHELL_USER_NAME}/.ssh
fi

# Setup basic firewall
if [ $SSH_PORT = '22' ]; then
    ufw allow ssh
else
    sed -i -e "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

    ufw allow $SSH_PORT/tcp
fi

# Restart ssh service to enable changes made
systemctl restart sshd

# TODO: cron-apt

# Setup fail2ban
apt-get install -y fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.loal
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -e "s/backend = .*/backend = systemd/" /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Fix backspace issue for shell scripts
stty erase ^H

# Setup FTP
apt-get install -y vsftpd

# Create FTP user
adduser --disabled-password --gecos "" $FTP_USER_NAME
echo "$FTP_USER_NAME:$FTP_USER_PASSWORD" | chpasswd

# Update FTP settings
sed -i -e "s/anonymous_enable=YES/anonymous_enable=NO/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/#chroot_local_user=YES/chroot_local_user=YES/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/listen_ipv6=YES/#listen_ipv6=YES/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/listen=NO/listen=YES/" /etc/vsftpd/vsftpd.conf

cat <<EOT >> /etc/vsftpd/vsftpd.conf
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
EOT

# Allow FTP through firewall
ufw allow ftp
ufw allow 20/tcp
ufw allow 40000:40100/tcp

# Start and enable FTP
systemctl start vsftpd
systemctl enable vsftpd

# Install Nginx
apt install -y nginx

# Allow through firewall
ufw allow 'Nginx HTTP'

# Install MariaDB
# TODO - get latest version
apt install -y mariadb-server mariadb-client

# TODO: secure install

# Install PHP
apt-get install -y php php-fpm php-common php-bcmath php-gd php-mbstring php-xmlrpc php-mysql php-imagick php-xml

# Install composer
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install Node and NPM
apt-get install -y nodejs

# Enable the firewall
ufw enable