#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Install the latest version of PHP.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_php() {
    print_info "Installing PHP"

    local PHP="php"

    if [[ ${IS_UBUNTU} = false ]]; then
        # Debian needs this for the newest php version
        apt-get install -y apt-transport-https lsb-release ca-certificates
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ \$(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

        update_system

        local PHP="php7.2"
    fi

    apt-get install -y ${PHP}-fpm ${PHP}-common ${PHP}-bcmath ${PHP}-gd ${PHP}-mbstring ${PHP}-xmlrpc ${PHP}-mysql ${PHP}-imagick ${PHP}-xml ${PHP}-zip
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
    sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 64M/" /etc/php/7.2/fpm/php.ini
    sed -i -e "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
    sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini

    # php-fpm config
    sed -i -e "s/user = .*/user = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/group = .*/group = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/;listen.owner = .*/listen.owner = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf
    sed -i -e "s/;listen.group = .*/listen.group = $FTP_USER_NAME/" /etc/php/7.2/fpm/pool.d/www.conf

    restart_php_fpm
}

##############################################
# Restart the PHP-FPM service.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function restart_php_fpm() {
    systemctl restart php7.2-fpm
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
    install_php
    configure_php
    init_site
}