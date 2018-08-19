#!/bin/bash

####################################################################
# Ubuntu 18.04 LTS linode stackscript for a new LEMP Stack install
# on a new server
#
# Monitor progress by: tail -f /root/stackscript.log
#
# Author: Randall Wilk <randall@randallwilk.com>
# Date: 08/16/2018
# Last Updated: 08/17/2018
##################################################################

# Define variables

#<UDF name="hostname" label="Enter main hostname for the new Linode server.">
#<UDF name="fqdn" label="Enter Server's Fully Qualified Domain Name (same as main hostname). Don't enter `www`">
#<UDF name="timezone" label="Server Timezone" default="America/Chicago" example="America/New_York">
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

IS_UBUNTU=false

function determine_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME

        if [[ ${OS} == Ubuntu* ]]; then
            IS_UBUNTU=true
        fi
    else
        echo Unable to determine Linux distribution
        exit
    fi
}

function install_debian() {
    echo "#### Installing Packages For Debian ####"

    apt-get install -y ntp ufw software-properties-common
}

function prevent_ip_spoofing() {
    if [ ${IS_UBUNTU} = true ]; then
        sed -i -e "s/order .*/order bind,hosts/" /etc/host.conf
        sed -i -e "s/multi on/nospoof on/" /etc/host.conf
    fi
}

function update_system() {
    apt-get update && apt-get upgrade -y
}

function install_nginx() {
    if [ ${IS_UBUNTU} = false ]; then
        add-apt-repository 'deb http://nginx.org/packages/debian/ stretch nginx'
        wget http://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key

        update_system
    fi

    # Now we can install nginx
    apt-get install -y nginx
}

function install_mariadb() {
    export DEBIAN_FRONTEND=noninteractive

    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password password $ROOT_DB_PASSWORD"
    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password_again password $ROOT_DB_PASSWORD"

    if [ ${IS_UBUNTU} = true ]; then
        add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main'
    else
        apt-get install -y dirmngr
    fi

    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

    if [ ${IS_UBUNTU} = false ]; then
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi

    apt-get install -y mariadb-server mariadb-client
}

function configure_mariadb() {
    # Run through the secure installation
    SECURE_MYSQL=$(expect -c "

    set timeout 3
    spawn mysql_secure_installation

    expect \"Enter current password for root (enter for none):\"
    send \"$ROOT_DB_PASSWORD\r\"

    expect \"Change the root password?\"
    send \"n\r\"

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

    # Setup remote db access
    mysql -u root -p$ROOT_DB_PASSWORD -e "GRANT ALL ON *.* TO '$DB_USER_NAME'@'%' IDENTIFIED BY '$DB_USER_PASSWORD' WITH GRANT OPTION;FLUSH PRIVILEGES;"
}

function configure_firewall() {
    # Allow SSH Connections
    if [ $SSH_PORT = '22' ]; then
        ufw allow OpenSSH
    else
        ufw allow $SSH_PORT/tcp
    fi

    # Allow FTP through firewall
    ufw allow ftp
    ufw allow 20/tcp
    ufw allow 40000:40100/tcp

    # Allow HTTP traffic through the firewall
    ufw allow 'Nginx HTTP'

    # Allow mariadb through firewall
    ufw allow mysql

    if [ $SSL = 'yes' ]; then
        # Allow https traffic through firewall
        ufw allow 'Nginx HTTPS'
    fi

    # Finally we can enable the firewall
    ufw enable
}

function install_php() {
    local PHP="php"

    if [ ${IS_UBUNTU} = false ]; then
        # Debian needs this for the newest php version
        apt-get install -y apt-transport-https lsb-release ca-certificates
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ \$(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

        update_system

        local PHP="php7.2"
    fi

    apt-get install -y ${PHP}-fpm ${PHP}-common ${PHP}-bcmath ${PHP}-gd ${PHP}-mbstring ${PHP}-xmlrpc ${PHP}-mysql ${PHP}-imagick ${PHP}-xml ${PHP}-zip
}

function configure_php() {
    # php.ini
    sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 64M/" /etc/php/7.2/fpm/php.ini
    sed -i -e "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
    sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini

    # php-fpm config
    sed -i -e "s/user = .*/user = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/group = .*/group = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/;listen.owner = .*/listen.owner = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/;listen.group = .*/listen.group = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf

    # Restart PHP-FPM
    systemctl restart php7.2-fpm
}

function init_site() {
    # Init site folder
    mkdir -p /home/$FTP_USER_NAME/logs
    mkdir -p /home/$FTP_USER_NAME/public_html/public

    # Create a test page
    touch /home/$FTP_USER_NAME/public_html/public/index.php
    echo "<?php phpinfo(); ?>" >> /home/$FTP_USER_NAME/public_html/public/index.php

    # Give FTP user ownership of the folders
    chown -R $FTP_USER_NAME:$FTP_USER_NAME /home/$FTP_USER_NAME
    chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/php
    chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/nginx

    # Restart nginx
    systemctl restart nginx
}

function configure_nginx() {
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
}

function configure_site_server_block() {
touch /etc/nginx/conf.d/$HOSTNAME.conf
cat <<EOT >> /etc/nginx/conf.d/$HOSTNAME.conf
server {
    listen 80;
    root /home/$FTP_USER_NAME/public_html/public;
    index index.php index.html;
    server_name $IPADDR www.$FQDN $FQDN;

    access_log /home/$FTP_USER_NAME/logs/access.log;
    error_log /home/$FTP_USER_NAME/logs/error.log;

    client_max_body_size 1024M;

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
        access_log off;
        expires  max;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
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

    location ~ /\.ht {
        deny all;
    }
}
EOT
}

function install_ssl_cert() {
    print_info "Installing LetsEncrypt SSL Certificate"

    apt-get install -y python-certbot-nginx

    CERTBOT_INSTALL_COMMAND="certbot --nginx"

    if [ $SSL_EMAIL = '' ]; then
        CERTBOT_INSTALL_COMMAND="$CERTBOT_INSTALL_COMMAND --register-unsafely-without-email"
    fi

    SSL_INSTALL=$(expect -c "

    set timeout 3
    spawn $CERTBOT_INSTALL_COMMAND

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

    # Restart nginx to enable changes
    systemctl restart nginx
}

function install_composer() {
    print_info "Installing Composer"
    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
}

function install_node() {
    print_info "Installing NodeJS & NPM"
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    apt-get install -y nodejs
    npm install npm@latest -g
}

function clean_up() {
    print_info "Cleaning Up"
    apt-get remove --purge -y expect
    apt-get autoremove -y
    apt-get clean
    apt-get autoclean
}

function print_info() {
    echo "#### $1 ####"
}

# Redirect output of this script to our logfile
exec &> /root/stackscript.log

echo "#### Install Start ####"

# Determine what os we are using
determine_os

# Update the system
update_system

# This sets the variable $IPADDR to the IPv4 address the new Linode receives.
IPADDR=$(hostname -I | cut -f1 -d' ')

# This sets the variable $IPADDR6 to the IPv6 address the new Linode receives.
IPADDR6=$(hostname -I | cut -f2 -d' ')

# If this is a debian distro, we need to install extra stuff
if [ ${IS_UBUNTU} = false ]; then
    install_debian
fi

# Install expect (will be removed at the end)
apt-get install -y expect

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

# Harden Server
if [ $ROOT_LOGIN = 'no' ]; then
    sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config

    # Add shell user to allowed users in /etc/ssh/sshd_config
    echo "AllowUsers $SHELL_USER_NAME" >> /etc/ssh/sshd_config
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

if [ $SSH_PORT != '22' ]; then
    sed -i -e "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
fi

# Prevent IP Spoofing
prevent_ip_spoofing

# Restart ssh service to enable changes made
systemctl restart sshd

# TODO: cron-apt

# Setup fail2ban
apt-get install -y fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -e "s/backend = .*/backend = systemd/" /etc/fail2ban/jail.local
systemctl restart fail2ban

# Fix backspace issue for shell scripts
stty erase ^H

# Setup FTP
apt-get install -y vsftpd

# Create FTP user
adduser --disabled-password --gecos "" $FTP_USER_NAME
echo "$FTP_USER_NAME:$FTP_USER_PASSWORD" | chpasswd

# Update FTP settings
sed -i -e "s/anonymous_enable=.*/anonymous_enable=NO/" /etc/vsftpd.conf
sed -i -e "s/.*chroot_local_user=.*/chroot_local_user=YES/" /etc/vsftpd.conf
sed -i -e "s/listen_ipv6=.*/#listen_ipv6=YES/" /etc/vsftpd.conf
sed -i -e "s/listen=.*/listen=YES/" /etc/vsftpd.conf

cat <<EOT >> /etc/vsftpd.conf
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
EOT

# Restart vsftpd service
systemctl restart vsftpd

# Install Nginx
install_nginx

# Install MariaDB
install_mariadb
configure_mariadb

# Install PHP
install_php

# Configure PHP & PHP-FPM
configure_php

# Configure Nginx
configure_nginx

# Configure site server block
configure_site_server_block

# Initialize site
init_site

# Install SSL Cert
if [ $SSL = 'yes' ]; then
    install_ssl_cert
fi

# Install composer
install_composer

# Install Node and NPM
install_node

# Configure the firewall
configure_firewall

# Clean up
clean_up

echo "#### Install Complete! ####"

echo "Rebooting server now..."
(sleep 5; reboot) &