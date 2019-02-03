#!/usr/bin/env bash

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
    print_info "Installing packages needed for Debian 9"

    apt-get install -y ufw software-properties-common
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
    # ../common/common.sh
    print_info "Performing Basic Setup"

    if [ $IS_UBUNTU = true ]
    then
       apt-get remove -y --purge keyboard-configuration
    fi

    # ./
    update_system

    if [ $IS_UBUNTU = false ]
    then
        # ./ | Debian 9 does not have some packages that Ubuntu 18.04 has pre-installed
        init_debian
    fi

    # ./
    install_temp_packages

    # ../common/basic-setup.sh
    set_timezone

    # ../common/basic-setup.sh
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
    # ../common/common.sh
    print_info "Updating System"

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y && apt-get upgrade -y
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

    # Fix backspace issues in terminal
    echo "stty erase ^H" >> ~/.bashrc # for root user
    echo "stty erase ^H" >> /home/$SHELL_USER_NAME/.bashrc # for the shell user
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
    print_info "Install Complete! Rebooting System..."

    sleep 5
    reboot
}