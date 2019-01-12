#!/usr/bin/env bash

##############################################
# Disables SELinux.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function disable_selinux() {
    print_info "Disabling SELinux"

    # Set to permissive to allow certain changes during install
    setenforce 0

    # Rebuild contents of selinux config b/c doing it with sed doesn't persist
    # changes when rebooted
    truncate -s 0 /etc/sysconfig/selinux
    cat <<EOT >> /etc/sysconfig/selinux
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOT
}

##############################################
# Perform basic server hardening operations.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################[
function harden_server() {
    print_info "Performing basic server hardening"

    # Create our sudo user
    add_sudo_user $SHELL_USER_NAME $SHELL_USER_PASSWORD

    prevent_root_ssh_login
    basic_server_ssh_harden
    set_ssh_port
    disable_ssh_password_login

    if [[ ${SSH_PORT} != '22' ]] && [[ ${SELINUX} != 'no' ]]; then
        # We need to let SELinux about the port change
        semanage port -a -t ssh_port_t -p tcp $SSH_PORT
    fi

    restart_ssh
}

##############################################
# Configure all our firewall rules.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_firewall() {
    # Allow SSH connections through
    firewall-cmd --add-port=$SSH_PORT/tcp --zone=public --permanent

    # Allow ftp through firewall
    firewall-cmd --add-port=20/tcp --zone=public --permanent
    firewall-cmd --add-port=20/udp --zone=public --permanent
    firewall-cmd --add-port=21/tcp --zone=public --permanent
    firewall-cmd --add-port=21/udp --zone=public --permanent
    firewall-cmd --add-port=40000-40100/tcp --zone=public --permanent
    firewall-cmd --add-port=40000-40100/udp --zone=public --permanent

    # Allow HTTP traffic through firewall
    firewall-cmd --add-port=80/tcp --zone=public --permanent
    firewall-cmd --add-service=http --zone=public --permanent

    # Allow mysql through firewall
    firewall-cmd --add-port=3306/tcp --zone=public --permanent

    if [[ ${SSL} = 'yes' ]]; then
        # Allow HTTPS traffic through firewall
        firewall-cmd --add-port=443/tcp --zone=public --permanent
        firewall-cmd --add-service=https --zone=public --permanent
    fi

    # Start and enable the firewall
    start_service firewalld
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

    $PKG_MANAGER install -y certbot-nginx

    local CERTBOT_INSTALL_COMMAND="certbot --nginx"

    if [[ ${SSL_EMAIL} = '' ]]; then
        local CERTBOT_INSTALL_COMMAND="$CERTBOT_INSTALL_COMMAND --register-unsafely-without-email"
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