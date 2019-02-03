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
    # ../common/common.sh
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

##############################################
# Add the given ftp user account.
# Globals:
#    None
# Arguments:
#   Username, Password
# Returns:
#   None
#############################################
function add_ftp_user() {
    # ../common/common.sh
    print_info "Creating FTP User: $1"

    adduser --disabled-password --no-create-home --home-dir /var/www/ --gecos "" $1
    echo "$1:$2" | chpasswd

    # add the ftp user to the nginx (www-data) group
    usermod -aG www-data $1

    # Give our ftp user ownership of the directory
    chown -R /var/www/ $1:www-data
}