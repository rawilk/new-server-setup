#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Determine which Linux distro is being used
# Globals:
#    OS
# Arguments:
#   None
# Returns:
#   None
#############################################
function determine_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    else
        echo Unable to determine Linux Distribution
        exit
    fi
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

# Run to set the OS variable
determine_os