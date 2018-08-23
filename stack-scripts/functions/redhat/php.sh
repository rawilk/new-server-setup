#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Install PHP.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_php() {
    local PHP='php72w'
    local PHP_MYSQL='mysql'

    if [[ ${IS_FEDORA} = true ]]; then
        local PHP='php'
        local PHP_MYSQL='mysqlnd'
    else
        rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    fi

    $PKG_MANAGER install -y ${PHP} ${PHP}-fpm ${PHP}-common ${PHP}-bcmath \
        ${PHP}-gd ${PHP}-mbstring ${PHP}-xmlrpc \
        ${PHP}-${PHP_MYSQL} ${PHP}-pdo ${PHP}-pecl-imagick ${PHP}-xml
}

##############################################
# Configure PHP.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_php() {
    # php.ini
    sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 64M/" /etc/php.ini
    sed -i -e "s/memory_limit = .*/memory_limit = 512M/" /etc/php.ini
    sed -i -e "s/.*cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" /etc/php.ini

    # php-fpm
    sed -i -e "s/user = .*/user = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
    sed -i -e "s/group = .*/group = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
    sed -i -e "s/listen = .*/listen = \/run\/php-fpm\/www.sock/" /etc/php-fpm.d/www.conf
    sed -i -e "s/.*listen.owner = .*/listen.owner = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf
    sed -i -e "s/.*listen.group = .*/listen.group = $FTP_USER_NAME/" /etc/php-fpm.d/www.conf

    start_service php-fpm
}

##############################################
# Run setup and install of PHP.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function setup_php() {
    print_info "Installing PHP"

    install_php
    configure_php
}