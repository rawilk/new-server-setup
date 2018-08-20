#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

################################################
# Basic functions for setup and clean up stuff
###############################################

##############################################
# Install some needed packages that are not
# pre-installed on Debian but are on Ubuntu
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function init_debian() {
    print_info "Installing packages needed for Debian"

    apt-get install -y ntp ufw software-properties-common
}

##############################################
# Install packages that will be purged after
# install.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_temp_packages() {
    apt-get install -y expect
}

##############################################
# Run basic setup operations.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function basic_setup() {
    update_system

    if [[ ${IS_UBUNTU} = false ]]; then
        init_debian
    fi

    install_temp_packages

    # Fix backspace issue for shell scripts in terminal
    ssty erase ^H

    set_timezone
    init_hosts
}

##############################################
# Update and upgrade the system packages.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function update_system() {
    apt-get update && apt-get upgrade -y
}

##############################################
# Remove some unneeded packages and clean up
# the system.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function cleanup() {
    print_info "Cleaning Up"

    apt-get remove --purge -y expect
    apt-get autoremove -y
    apt-get clean
    apt-get autoclean
}

##############################################
# Reboot the system.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function reboot_system() {
    print_info "Rebooting System..."

    sleep 5
    reboot
}