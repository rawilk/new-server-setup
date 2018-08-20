#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Install Composer
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_composer() {
    print_info "Installing Composer"

    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
}

##############################################
# Install fail2ban
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_fail2ban() {
    print_info "Installing Fail2Ban"

    apt-get install -y fail2ban
    cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -i -e "s/backend = .*/backend = systemd/" /etc/fail2ban/jail.local
    systemctl restart fail2ban
}

##############################################
# Install NodeJS and NPM.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_node() {
    print_info "Installing NodeJS & NPM"

    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    apt-get install -y nodejs
    npm install npm@latest -g
}

##############################################
# Run all util install functions.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_utils() {
    install_composer
    install_fail2ban
    install_node
}