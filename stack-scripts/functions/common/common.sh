#!/usr/bin/env bash

##############################################
# Determine which Linux distro is being used
# Globals:
#    OS, OS_VERSION
# Arguments:
#   None
# Returns:
#   None
#############################################
function determine_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    else
        echo Unable to determine Linux Distribution
        exit
    fi
}

##############################################
# Sets variables for the ipv4 and ipv6 ip
# address the new Linode receives.
# Globals:
#    IPADDR, IPADDR6
# Arguments:
#   None
# Returns:
#   None
#############################################
function determine_ip() {
    # This sets the variable $IPADDR to the IPv4 address the new Linode receives.
    IPADDR=$(hostname -I | cut -f1 -d' ')

    # This sets the variable $IPADDR6 to the IPv6 address the new Linode receives.
    IPADDR6=$(hostname -I | cut -f2 -d' ')
}

##############################################
# Prints the given argument for consistent
# messages
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function print_info() {
    echo
    echo "#### $1 ####"
    echo
}

# Set the global variables
determine_os
determine_ip