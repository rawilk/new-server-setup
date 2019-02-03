#!/usr/bin/env bash

#############################################
# These are scripts that can work across
# different distros
############################################

##############################################
# If user doesn't want root to ssh login,
# prevent them from doing so.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function prevent_root_ssh_login() {
    if [ $ROOT_LOGIN = 'no' ]
    then
        sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config

        # Add sudo user to allowed users in /etc/ssh/sshd_config
        echo "AllowUsers $SHELL_USER_NAME" >> /etc/ssh/sshd_config
    fi
}

##############################################
# Perform some basic server hardening steps
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function basic_server_ssh_harden() {
    sed -i -e "s/.*AddressFamily .*/AddressFamily inet/" /etc/ssh/sshd_config
    sed -i -e "s/.*LoginGraceTime .*/LoginGraceTime 1m/" /etc/ssh/sshd_config
    sed -i -e "s/.*ClientAliveInterval .*/ClientAliveInterval 600/" /etc/ssh/sshd_config
    sed -i -e "s/.*ClientAliveCountMax .*/ClientAliveCountMax 0/" /etc/ssh/sshd_config
}

##############################################
# Disable password login and setup ssh keys.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function disable_ssh_password_login() {
    # Disable password login
    if [[ $PASSWORD_LOGIN = 'no' ]] && [[ $SSH_PUB_KEY != '' ]]
    then
        sed -i -e "s/.*PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
    fi

    # Setup ssh keys
    if [ $SSH_PUB_KEY != '' ]
    then
        mkdir -p /root/.ssh
        mkdir -p /home/$SHELL_USER_NAME/.ssh
        echo "$SSH_PUB_KEY" > /root/.ssh/authorized_keys
        echo "$SSH_PUB_KEY" > /home/$SHELL_USER_NAME/.ssh/authorized_keys
        chmod -R 700 /root/.ssh
        chmod -R 700 /home/${SHELL_USER_NAME}/.ssh
        chown -R ${SHELL_USER_NAME}:${SHELL_USER_NAME} /home/${SHELL_USER_NAME}/.ssh
    fi
}

##############################################
# Restart the sshd service.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function restart_ssh() {
    systemctl restart sshd
}

##############################################
# Change the ssh port if necessary.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function set_ssh_port() {
    if [ $SSH_PORT != '22' ]
    then
        sed -i -e "s/.*Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    fi
}