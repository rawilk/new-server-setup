#!/usr/bin/env bash

# Redirect the output of this script to our logfile
exec &> /root/stackscript.log

curl -o /root/stack-includes.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/functions/debian-based/includes.sh

. /root/stack-includes.sh

# ./functions/common/common.sh
print_info "Install Start"

# ./functions/debian-based/setup-teardown.sh
basic_setup

# ./functions/debian-based/harden-server.sh
harden_server

if [ "$INSTALL_WEBSERVER" = 'yes' ]
then
    # ./functions/debian-based/nginx.sh
    install_nginx

    # ./functions/debian-based/ftp.sh
    setup_ftp

    # ./functions/debian-based/php.sh
    setup_php
fi