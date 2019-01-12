#!/usr/bin/env bash

##############################################
# Configure Nginx for the new server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
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

##############################################
# Configure the main site server block.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
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
}

##############################################
# Install nginx on the server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_nginx() {
    $PKG_MANAGER install -y nginx
    start_service nginx
}

##############################################
# Restart the nginx service.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function restart_nginx() {
    systemctl restart nginx
}

##############################################
# Initialize the site with a basic index.php
# file so we can see the site is ready to go.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
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
    chown -R $FTP_USER_NAME:$FTP_USER_NAME /var/lib/php-fpm

    restart_nginx
}

##############################################
# Setup nginx and site server blocks to serve
# a test page.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function setup_site() {
    configure_nginx
    configure_site_server_block
    init_site
}