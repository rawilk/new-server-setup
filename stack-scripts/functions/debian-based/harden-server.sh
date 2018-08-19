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

    restart_ssh
}