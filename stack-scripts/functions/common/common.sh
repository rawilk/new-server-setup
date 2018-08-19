#!/usr/bin/env bash

# Determine which Linux distro we are using
function determine_os() {
    if [ -f /etc/os-release ]; then
        . etc/os-release
        OS=$NAME
    else
        echo Unable to determine Linux Distribution
        exit
    fi
}

# Print info - keeps info outputted by the script consistent
function print_info() {
    echo
    echo "#### $1 ####"
    echo
}