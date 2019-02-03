#!/usr/bin/env bash

##############################################
# Configure ftp for the server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_ftp() {
    # make a backup of the original config first
    cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

    # Update vsftpd settings
    sed -i -e "s/anonymous_enable=.*/anonymous_enable=NO/" /etc/vsftpd.conf
    sed -i -e "s/.*chroot_local_user=.*/chroot_local_user=YES/" /etc/vsftpd.conf
    sed -i -e "s/listen_ipv6=.*/#listen_ipv6=YES/" /etc/vsftpd.conf
    sed -i -e "s/listen=.*/listen=YES/" /etc/vsftpd.conf

cat <<EOT >> /etc/vsftpd.conf
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
EOT
}

##############################################
# Install vsftpd
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_ftp() {
    apt-get install -y vsftpd
}

##############################################
# Restart the vsftpd service.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function restart_ftp() {
    systemctl restart vsftpd
}

##############################################
# Setup ftp for the server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function setup_ftp() {
    # ../common/common.sh
    print_info "Installing and setting up FTP"

    # ./
    install_ftp

    # ./users.sh | Create our ftp user
    add_ftp_user $FTP_USER_NAME $FTP_USER_PASSWORD

    # ./
    configure_ftp

    # ./
    restart_ftp
}