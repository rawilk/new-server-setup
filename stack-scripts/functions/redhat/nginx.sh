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
    # back up the file first
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk

    truncate -s 0 /etc/nginx/nginx.conf

    cat <<EOT >> /etc/nginx/nginx.conf
user $FTP_USER_NAME;
worker_processes auto;
pid /run/nginx.pid;

error_log /var/log/nginx/error.log;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 4096;
}

http {
    include /etc/nginx/mime.types;

    default_type application/octet-stream;

    log_format   main '\$remote_addr - \$remote_user [\$time_local]  \$status '
    '"\$request" \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    client_max_body_size 64M;
    keepalive_timeout 65;
    types_hash_max_size 2048; # internal parameter to speed up hashtable lookups

    gzip on;
    gzip_vary on; # tells proxies to cache both gzipped and regular versions of a resource
    gzip_min_length 10240; # compress nothing less than 1024
    gzip_comp_level 5; # offers about a 75% reduction for most ASCII files (almost identical to level 9)
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
    gzip_disable "MSIE [1-6]\."; # disable compression for Internet Explorer versions 1-6

    # include all site virtual host files
    include /etc/nginx/conf.d/*.conf
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
    touch /etc/nginx/conf.d/$FQDN.conf

    cat <<EOT >> /etc/nginx/conf.d/$FQDN.conf
server {
    listen 80;
    listen [::]:80;

    server_name $IPADDR www.$FQDN $FQDN;
    root /var/www/$FQDN;
    index index.php index.html;

    access_log /var/log/nginx/$FQDN.access.log;
    error_log /var/www/nginx/$FQDN.error.log;

    charset utf-8;
    client_max_body_size = 1024M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }

    location ~/\.ht {
        deny all;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~/.well-known {
        allow all;
    }

    location /favicon.ico {
        access_log off;
        expires max;
    }

    location /robots.txt {
        access_log off;
        expires max;
    }

    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        access_log off;
        log_not_found off;
        expires max;
    }
}
EOT

# create a backup of the virtual host file
cp /etc/nginx/conf.d/$FQDN.conf /etc/nginx/conf.d/$FQDN.conf.bk
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
    mkdir -p /var/www/$FQDN
    mkdir -p /home/$FTP_USER_NAME/logs

    # Create a test page
    touch /var/www/$FQDN/index.php
    echo "<?php phpinfo(); ?>" >> /var/www/$FQDN/index.php

    # Give FTP user ownership of the folders
    chown -R $FTP_USER_NAME:nginx /var/www
    chown -R $FTP_USER_NAME:nginx /var/lib/php
    chown -R $FTP_USER_NAME:nginx /var/lib/nginx
    chown -R $FTP_USER_NAME:nginx /var/lib/php-fpm
    chown -R $FTP_USER_NAME:nginx /var/log/nginx

    find /var/www/ -type d -exec chmod 775 {} +
    find /var/www/ -type f -exec chmod 664 {} +

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