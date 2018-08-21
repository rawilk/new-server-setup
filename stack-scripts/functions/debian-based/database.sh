#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

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
    export DEBIAN_FRONTEND=noninteractive

    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password password $ROOT_DB_PASSWORD"
    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password_again password $ROOT_DB_PASSWORD"
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

    if [[ ${IS_UBUNTU} = true ]]; then
        add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main'
    else
        apt-get install -y dirmngr
    fi

    if [[ ${IS_UBUNTU} = false ]]; then
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    fi

    apt-get install -y mariadb-server mariadb-client
}

##############################################
# Configure mariadb on the server.
# Globals:
#    None
# Arguments:
#   None
# Returns:
#   None
#############################################
function configure_mariadb() {
    # Run through the secure installation
    SECURE_MYSQL=$(expect -c "

    set timeout 3
    spawn mysql_secure_installation

    expect \"Enter current password for root (enter for none):\"
    send \"$ROOT_DB_PASSWORD\r\"

    expect \"Change the root password?\"
    send \"n\r\"

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