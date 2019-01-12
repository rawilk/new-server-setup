#!/usr/bin/env bash

####################################################################
# Date: 08/04/2018
# Last Updated: 08/22/2018
#
# Linode stack script to configure and install a LEMP stack on a
# Redhat based server.
#
# Compatible with:
#    - CentOS 7
#    - Fedora 28
#
# Monitor progress by: tail -f /root/stackscript.log
##################################################################

# Redirect output of this script to our logfile
exec &> /root/stackscript.log

curl -o /root/redhat-includes.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/functions/redhat/includes.sh

. /root/redhat-includes.sh

print_info "Install Start"

basic_setup
harden_server
setup_ftp
install_nginx
setup_database
setup_php
setup_site

if [[ ${SSL} = 'yes' ]]; then
    install_ssl_cert
fi

install_utils
configure_firewall
cleanup
reboot_system