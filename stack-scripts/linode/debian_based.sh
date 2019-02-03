#!/bin/bash

#<UDF name="hostname" label="Enter main hostname for the new Linode server." default="">
#<UDF name="fqdn" label="Enter Server's Fully Qualified Domain Name (same as main hostname). Don't enter `www`">
#<UDF name="timezone" label="Server Timezone" default="UTC" example="America/New_York">

#### SSH
#<UDF name="ssh_pub_key" label="SSH pubkey (installed for root and shell user)" example="ssh-rsa ..." default="">
#<UDF name="password_login" label="Permit SSH Password Login" oneOf="no,yes" default="no">
#<UDF name="ssh_port" label="SSH Port" default="22">
#<UDF name="root_login" label="Permit Root SSH Login?" oneOf="no,yes" default="no">
#<UDF name="shell_user_name" label="Shell User Name">
#<UDF name="shell_user_password" label="Shell User Password">

#### FTP
#<UDF name="install_webserver" label="Install Webserver?" oneOf="no,yes" default="yes">
#<UDF name="ftp_user_name" label="FTP User Name" default="">
#<UDF name="ftp_user_password" label="FTP User Password" default="">

#### Database
#<UDF name="install_mysql" label="Install MySQL?" oneOf="no,yes" default="yes">
#<UDF name="root_db_password" label="Database User Name" default="">
#<UDF name="db_user_name" label="Remote Database User Name" default="">
#<UDF name="db_user_password" label="Remote Database User Password" default="">

#### SSL
#<UDF name="ssl" label="Install SSL Certificate?" oneOf="no,yes" default="no">
#<UDF name="ssl_email" label="SSL Renewal and Security Notices Email" default="">

# Retrieve main install script from git repository
curl -o /root/init.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/ubuntu-18-lemp-stack.sh

# Execute main install script
. ./root/init.sh