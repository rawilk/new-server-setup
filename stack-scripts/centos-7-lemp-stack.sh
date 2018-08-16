#!/bin/bash

############################################################
# CentOS 7 linode stackscript for a new LEMP Stack install
# on a new server
#
# Monitor progress by: tail -f /root/stackscript.log
#
# Author: Randall Wilk <randall@randallwilk.com>
# Date: 08/04/2018
# Last Updated: 08/16/2018
###########################################################

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

# Disable SELinux (this will require a server reboot after install is complete)
if [ $SELINUX = 'no' ]; then
    # Set to permissive to allow certain changes during install
    setenforce 0

    # Rebuild contents of selinux config b/c find and replace doesn't do it for some reason
    truncate -s 0 /etc/sysconfig/selinux

    cat <<EOT >> /etc/sysconfig/selinux
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOT
fi

# Update yum
yum -y update

# Install epel-release
yum -y install epel-release

# This section sets the hostname.
hostnamectl set-hostname $FQDN --static

# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts
echo $IPADDR6 $FQDN $HOSTNAME >> /etc/hosts

# Setup timezone
timedatectl set-timezone "$TIMEZONE"

# Install NTP date sync
yum -y install ntp
systemctl start ntpd
systemctl enable ntpd

# Create the dedicated shell user
useradd $SHELL_USER_NAME && echo $SHELL_USER_PASSWORD | passwd $SHELL_USER_NAME --stdin
usermod -aG wheel $SHELL_USER_NAME

# Change SSH Port
if [ $SSH_PORT != '22' ]; then
    sed -i -e "s/.*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config

    if [ $SELINUX != 'no' ]; then
        # Let SELinux know about port change
        semanage port -a -t ssh_port_t -p tcp $SSH_PORT
    fi
fi

# Ban root from logging in remotely
if [ $ROOT_LOGIN = 'no' ]; then
    sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config

    # Allow shell user to ssh in
    echo "AllowUsers $SHELL_USER_NAME" >> /etc/ssh/sshd_config
fi

# Harden server
sed -i -e "s/.*AddressFamily .*/AddressFamily inet/" /etc/ssh/sshd_config
sed -i -e "s/.*LoginGraceTime .*/LoginGraceTime $LOGIN_GRACE_TIME/" /etc/ssh/sshd_config
sed -i -e "s/.*ClientAliveInterval .*/ClientAliveInterval 600/" /etc/ssh/sshd_config
sed -i -e "s/.*ClientAliveCountMax .*/ClientAliveCountMax 0/" /etc/ssh/sshd_config

# Disable ssh password login
if [ $PASSWORD_LOGIN = 'no' ] && [ $SSH_PUB_KEY != '' ]; then
    sed -i -e "s/PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
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

# Restart sshd to implement changes made
systemctl restart sshd

# Setup the firewall
systemctl start firewalld
systemctl enable firewalld

if [ $SSH_PORT != '22' ]; then
    firewall-cmd --add-port=$SSH_PORT/tcp --zone=public --permanent
    firewall-cmd --reload
fi

# Install yum utils
yum -y install yum-utils

# Install htop
yum -y install htop

# Setup automatic updates
yum -y install yum-cron
sed -i -e "s/apply_updates = .*/apply_updates = yes/" /etc/yum/yum-cron.conf

# Setup fail2ban
yum -y install fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.loal
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -e "s/backend = .*/backend = systemd/" /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Install wget
yum -y install wget

# Fix backspace issue for shell scripts
stty erase ^H

# Setup FTP
yum -y install vsftpd

# Create FTP user account
useradd $FTP_USER_NAME && echo $FTP_USER_PASSWORD | passwd $FTP_USER_NAME --stdin

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

# Configure firewall for FTP
firewall-cmd --add-port=20/tcp --zone=public --permanent
firewall-cmd --add-port=20/udp --zone=public --permanent
firewall-cmd --add-port=21/tcp --zone=public --permanent
firewall-cmd --add-port=21/udp --zone=public --permanent
firewall-cmd --add-port=40000-40100/tcp --zone=public --permanent
firewall-cmd --add-port=40000-40100/udp --zone=public --permanent
firewall-cmd --reload

# Start and enable FTP
systemctl start vsftpd
systemctl enable vsftpd

# Install MariaDB
touch /etc/yum.repos.d/MariaDB.repo
cat <<EOT >> /etc/yum.repos.d/MariaDB.repo
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.3.8/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOT

yum -y install mariadb mariadb-server
systemctl start mariadb
systemctl enable mariadb

# MySQL Secure Install
yum -y install expect

SECURE_MYSQL=$(expect -c "

set timeout 3
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"

expect \"root password?\"
send \"y\r\"

expect \"New password:\"
send \"$ROOT_DB_PASSWORD\r\"

expect \"Re-enter new password:\"
send \"$ROOT_DB_PASSWORD\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")

echo "$SECURE_MYSQL"

# Bind IP to mysql
cat <<EOT >> /etc/my.cnf
[mysqld]
bind-address=$IPADDR
EOT

# Restart mariadb
systemctl restart mariadb

# Configure firewall for mysql
firewall-cmd --add-port=3306/tcp --zone=public --permanent
firewall-cmd --reload

# Setup remote db access
mysql -u root -p$ROOT_DB_PASSWORD -e "GRANT ALL ON *.* TO '$DB_USER_NAME'@'%' IDENTIFIED BY '$DB_USER_PASSWORD' WITH GRANT OPTION;FLUSH PRIVILEGES;"

# Install PHP and Nginx
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install nginx php72w-fpm php72w-common php72w-bcmath php72w-gd php72w-mbstring php72w-xmlrpc php72w-mysql php72w-pdo php72w-pecl-imagick php72w-xml

# Configure firewall
firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=443/tcp --zone=public --permanent
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload

# Configure Nginx
truncate -s 0 /etc/nginx/nginx.conf
cat <<EOT >> /etc/nginx/nginx.conf
user $FTP_USER_NAME;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    gzip on;
    gzip_comp_level 3;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain application/x-javascript text/xml text/css application/xml;

    client_max_body_size 64M;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
EOT

# Configure site server block
touch /etc/nginx/conf.d/$HOSTNAME.conf
cat <<EOT >> /etc/nginx/conf.d/$HOSTNAME.conf
server {
    listen 80;

    server_name $IPADDR www.$FQDN $FQDN;
    root /home/$FTP_USER_NAME/public_html/public;

    access_log /home/$FTP_USER_NAME/logs/access.log;
    error_log /home/$FTP_USER_NAME/logs/error.log;

    client_max_body_size 1024M;
    index index.php index.html;

    location /favicon.ico {
        access_log off;
        expires max;
    }

    location /robots.txt {
        access_log off;
        expires max;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
        access_log        off;
        expires           max;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        client_max_body_size 1024M;
    }

    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
}
EOT

# Init site folder
mkdir -p /home/$FTP_USER_NAME/logs
mkdir -p /home/$FTP_USER_NAME/public_html/public

# Create a test page
touch /home/$FTP_USER_NAME/public_html/public/index.php
echo "<?php phpinfo(); ?>" >> /home/$FTP_USER_NAME/public_html/public/index.php

# Give FTP user ownership of the folders
chown -R $FTP_USER_NAME:$FTP_USER_NAME /home/$FTP_USER_NAME

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Configure PHP-FPM
sed -i -e "s/user = apache/user = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/group = apache/group = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/listen = 127.0.0.1:9000/listen = \/run\/php-fpm\/www.sock/" /etc/php-fpm.d/www.conf
sed -i -e "s/;listen.owner = nobody/listen.owner = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/;listen.group = nobody/listen.group = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf

# Configure PHP
sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 64M/" /etc/php.ini
sed -i -e "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini

# Start and enable PHP-FPM
systemctl start php-fpm
systemctl enable php-fpm

# Give FTP user proper ownership
chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/php
chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/nginx
chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/php-fpm

# Install cert
if [ $SSL = 'yes' ]; then
    yum -y install certbot-nginx

    SSL_INSTALL=$(expect -c "

    set timeout 3
    spawn certbot --nginx

    expect \"Enter email address (used for urgent renewal and security notices)\"
    send \"$SSL_EMAIL\r\"

    expect \"Please read the Terms of Service at\"
    send \"a\r\"

    expect \"Would you be willing to share your email address\"
    send \"n\r\"

    expect \"Which names would you like to activate HTTPS for?\"
    send \"\r\"

    expect \"Waiting for verification...\"
    send \"\r\"

    expect \"Cleaning up challenges\"
    send \"\r\"

    expect \"Deploying Certificate\"
    send \"\r\"

    expect \"Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.\"
    send \"2\r\"

    expect eof
    ")

    echo "$SSL_INSTALL"

    # Auto-renew certs
    crontab -l | { cat; echo "0 * * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew"; } | crontab -

    # Disable TLS v1.0
    sed -i -e "s/ssl_protocols .*/ssl_protocols TLSv1.1 TLSv1.2;/" /etc/letsencrypt/options-ssl-nginx.conf

    # Restart nginx to enact changes
    systemctl restart nginx

    # Allow https traffic through firewall
    firewall-cmd --add-service=https --zone=public --permanent
    firewall-cmd --reload
fi

# Install composer
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install Node and NPM
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
yum -y install nodejs
npm install npm@latest -g

# clean up
yum -y remove expect
yum clean all
rm -rf /var/cache/yum

echo "#### Install complete ####"

if [ $SELINUX = 'no' ]; then
    echo "Rebooting server to disable SELinux..."
    (sleep 5; reboot) &
fi