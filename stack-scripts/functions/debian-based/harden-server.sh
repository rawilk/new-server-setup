#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Helps prevent ip spoofing.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function prevent_ip_spoofing() {
    if [[ ${IS_UBUNTU} = true ]]; then
        sed -i -e "s/order .*/order bind,hosts/" /etc/host.conf
        sed -i -e "s/multi on/nospoof on/" /etc/host.conf
    fi
}

function harden_server() {
    print_info "Performing basic server hardening"

    # Create our sudo user
    add_sudo_user $SHELL_USER_NAME $SHELL_USER_PASSWORD

    prevent_root_ssh_login
    basic_server_ssh_harden
    set_ssh_port
    prevent_ip_spoofing
    disable_ssh_password_login

    restart_ssh
}

##############################################
# Configure all the firewall rules
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_firewall() {
    # Allow SSH connections
    if [[ $SSH_PORT = '22' ]]; then
        ufw allow OpenSSH
    else
        ufw allow $SSH_PORT/tcp
    fi

    # Allow FTP through firewall
    ufw allow ftp
    ufw allow 20/tcp
    ufw allow 40000:40100/tcp

    # Allow HTTP traffic through firewall
    ufw allow 'Nginx HTTP'

    # Allow database through firewall
    ufw allow mysql

    if [[ $SSL = 'yes' ]]; then
        # Allow HTTPS traffic through firewall
        ufw allow 'Nginx HTTPS'
    fi

    # Enable the firewall
    ufw enable
}