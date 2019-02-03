#!/usr/bin/env bash

##############################################
# Add the given user to the server.
# Globals:
#    Username, Password
# Arguments:
#   None
# Returns:
#   None
#############################################
function add_user() {
    print_info "Creating User: $1"

    adduser --disabled-password --gecos "" $1
    echo "$1:$2" | chpasswd
}

##############################################
# Add the given sudo user.
# Globals:
#    Username, Password
# Arguments:
#   None
# Returns:
#   None
#############################################
function add_sudo_user() {
    # ./
    add_user $1 $2

    usermod -aG sudo $1
}