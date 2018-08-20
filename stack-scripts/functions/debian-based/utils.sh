#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

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
# Run all util install functions.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_utils() {
    install_fail2ban
}