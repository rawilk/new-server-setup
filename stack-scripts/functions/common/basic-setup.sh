#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com

##############################################
# Set the timezone from the user defined
# variables from linode.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function set_timezone() {
    timedatectl set-timezone "$TIMEZONE"
}

##############################################
# Setup hostname related stuff.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function init_hosts() {
    # Set the hostname
    local HOST=$FQDN
    if [ $HOST = '' ]
    then
        local HOST=$HOSTNAME
    fi
    hostnamectl set-hostname $HOST --static

    # This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
    if [ $FQDN != '' ]
    then
        echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts
        echo $IPADDR6 $FQDN $HOSTNAME >> /etc/hosts
    fi
}