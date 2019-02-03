#!/usr/bin/env bash

##############################################
# Perform some basic server hardening
# measures.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function harden_server() {
    # ../common/common.sh
    print_info "Performing basic server hardening"

    # Create our sudo user
    # ./users.sh
    add_sudo_user $SHELL_USER_NAME $SHELL_USER_PASSWORD

    # ../common/harden-server.sh | Only disables if option set to 'no'
    prevent_root_ssh_login

    # ../common/harden-server.sh
    basic_server_ssh_harden

    # ../common/harden-server.sh
    set_ssh_port

    # ../common/harden-server.sh | Only disables if an ssh key is provided and option is set to 'no'
    disable_ssh_password_login

    # ../common/harden-server.sh
    restart_ssh
}

##############################################
# Configure all the firewall rules
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_firewall() {
    # Allow SSH connections
    if [[ $SSH_PORT = '22' ]]; then
        ufw allow OpenSSH
    else
        ufw allow $SSH_PORT/tcp
    fi

    # Allow FTP through firewall
    ufw allow ftp
    ufw allow 20/tcp
    ufw allow 40000:40100/tcp

    # Allow HTTP traffic through firewall
    if [[ ${IS_UBUNTU} = true ]]; then
        ufw allow 'Nginx HTTP'
    else
        ufw allow 80/tcp
    fi

    # Allow database through firewall
    ufw allow mysql

    if [[ $SSL = 'yes' ]]; then
        # Allow HTTPS traffic through firewall
        if [[ ${IS_UBUNTU} = true ]]; then
            ufw allow 'Nginx HTTPS'
        else
            ufw allow 443/tcp
        fi
    fi

    # Enable the firewall
    ufw enable
}

##############################################
# Install a LetsEncrypt SSL Certificate.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_ssl_cert() {
    print_info "Installing LetsEncrypt SSL Certificate"

    apt-get install -y python-certbot-nginx

    CERTBOT_INSTALL_COMMAND="certbot --nginx"

    if [[ $SSL_EMAIL = '' ]]; then
        CERTBOT_INSTALL_COMMAND="$CERTBOT_INSTALL_COMMAND --register-unsafely-without-email"
    fi

    SSL_INSTALL=$(expect -c "

    set timeout 3
    spawn $CERTBOT_INSTALL_COMMAND

    expect \"Enter email address (used for urgent renewal and security notices)\"
    send \"$SSL_EMAIL\r\"

    expect \"Please read the Terms of Service at\"
    send \"a\r\"

    expect \"Would you be willing to share your email address\"
    send \"n\r\"

    expect \"Which names would you like to activate HTTPS for?\"
    send \"\r\"

    expect \"Waiting for verification...\"
    send \"\r\"

    expect \"Cleaning up challenges\"
    send \"\r\"

    expect \"Deploying Certificate\"
    send \"\r\"

    expect \"Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.\"
    send \"2\r\"

    expect eof
    ")

    echo "$SSL_INSTALL"

    # Auto-renew certs
    crontab -l | { cat; echo "0 * * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew"; } | crontab -

    # Disable TLS v1.0
    sed -i -e "s/ssl_protocols .*/ssl_protocols TLSv1.1 TLSv1.2;/" /etc/letsencrypt/options-ssl-nginx.conf

    # Restart nginx to enable changes
    restart_nginx
}