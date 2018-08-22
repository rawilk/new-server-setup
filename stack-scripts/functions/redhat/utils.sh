#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Install Composer.
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
# Install fail2ban service.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_fail2ban() {
    print_info "Installing fail2ban"

    yum -y install fail2ban
    cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.loal
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -i -e "s/backend = .*/backend = systemd/" /etc/fail2ban/jail.local
    systemctl enable fail2ban
    systemctl start fail2ban
}

##############################################
# Install htop
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_htop() {
    print_info "Installing htop"
    
    yum install -y htop
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

    curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
    yum install -y nodejs
    npm install npm@latest -g
}

##############################################
# Install ntp to keep server clock in sync.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_ntp() {
    print_info "Installing NTP"
    
    yum install -y ntp
    systemctl start ntpd
    systemctl enable ntpd
}

##############################################
# Setup automatic updates.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_yum_cron() {
    print_info "Installing yum-cron"

    yum -y install yum-cron
    sed -i -e "s/apply_updates = .*/apply_updates = yes/" /etc/yum/yum-cron.conf
}

##############################################
# Install our util packages and other helpful
# packages.
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
    install_htop
    install_node
    install_ntp
    install_yum_cron
}

##############################################
# Start and enable the given service.
# Globals:
#   None
# Arguments:
#   Service name
# Returns:
#   None
#############################################
function start_service() {
    systemctl start $1
    systemctl enable $1
}