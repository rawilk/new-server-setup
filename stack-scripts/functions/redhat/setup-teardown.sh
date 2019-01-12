#!/usr/bin/env bash

##############################################
# Run initial setup operations.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function basic_setup() {
    print_info "Performing Basic Setup"

    if [[ ${SELINUX} = 'no' ]]; then
        disable_selinux
    fi

    update_system
    install_needfulls
    install_temp_packages

    # Fix backspace issue for shell scripts in terminal
    stty erase ^H

    set_timezone
    init_hosts
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
    $PKG_MANAGER install -y expect
}

##############################################
# Install packages to help installation
# run smoothly.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_needfulls() {
    if [[ ${IS_FEDORA} = true ]]; then
        dnf install -y dnf-plugins-core
    else
        yum install -y epel-release yum-utils wget
    fi
}

##############################################
# Update system packages.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function update_system() {
    if [[ ${IS_FEDORA} = true ]]; then
        dnf upgrade -y
    else
        yum update -y
    fi
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

    $PKG_MANAGER remove -y expect
    $PKG_MANAGER clean all
    rm -rf /var/cache/yum
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