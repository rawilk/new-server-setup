#!/usr/bin/env bash

##############################################
# Install mariadb database.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function install_mariadb() {
    touch /etc/yum.repos.d/MariaDB.repo

    local BASEURL='http://yum.mariadb.org/10.3/centos7-amd64'

    if [[ ${IS_FEDORA} = true ]]; then
        local BASEURL='http://yum.mariadb.org/10.3/fedora28-amd64'
    fi

    cat <<EOT >> /etc/yum.repos.d/MariaDB.repo
[mariadb]
name=MariaDB
baseurl=${BASEURL}
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOT

    $PKG_MANAGER install -y mariadb mariadb-server
    start_service mariadb
}

function configure_mariadb() {
    # MySQL Secure Install
    SECURE_MYSQL=$(expect -c "

    set timeout 3
    spawn mysql_secure_installation

    expect \"Enter current password for root (enter for none):\"
    send \"\r\"

    expect \"root password?\"
    send \"y\r\"

    expect \"New password:\"
    send \"$ROOT_DB_PASSWORD\r\"

    expect \"Re-enter new password:\"
    send \"$ROOT_DB_PASSWORD\r\"

    expect \"Remove anonymous users?\"
    send \"y\r\"

    expect \"Disallow root login remotely?\"
    send \"y\r\"

    expect \"Remove test database and access to it?\"
    send \"y\r\"

    expect \"Reload privilege tables now?\"
    send \"y\r\"

    expect eof
    ")

    echo "$SECURE_MYSQL"

    # Bind IP to mysql
    cat <<EOT >> /etc/my.cnf
[mysqld]
bind-address=$IPADDR
EOT

    # Restart mariadb
    systemctl restart mariadb

    # Setup remote db access
    mysql -u root -p$ROOT_DB_PASSWORD -e "GRANT ALL ON *.* TO '$DB_USER_NAME'@'%' IDENTIFIED BY '$DB_USER_PASSWORD' WITH GRANT OPTION;FLUSH PRIVILEGES;"
}

##############################################
# Setup the database on the server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function setup_database() {
    print_info "Installing MariaDB"

    install_mariadb
    configure_mariadb
}