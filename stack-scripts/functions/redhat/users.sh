#!/usr/bin/env bash

##############################################
# Add the given user account.
# Globals:
#    None
# Arguments:
#   Username, Password
# Returns:
#   None
#############################################
function add_user() {
    print_info "Creating User: $1"

    useradd $1 && echo $2 | passwd $1 --stdin
}

##############################################
# Add the given user as a sudo user.
# Globals:
#    None
# Arguments:
#   Username, Password
# Returns:
#   None
#############################################
function add_sudo_user() {
    add_user $1 $2
    usermod -aG wheel $1
}