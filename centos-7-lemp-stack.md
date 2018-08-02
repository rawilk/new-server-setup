# New Server Setup

This guide assumes a Centos 7 operating system and you are setting a LEMP stack up. It also assumes you know how to point a domain name to your server's IP address. For best results, complete guide from top to bottom.

## Ensure that SELINUX is disabled

##### Run

```bash
sestatus
```

If this says enabled, do the following (otherwise skip to the next step):

```bash
nano /etc/sysconfig/selinux
```

##### Change

```bash
From: SELINUX=enforcing | To: SELINUX=disabled
```

- Save and exit
- Reboot server

## Set the Timezone (optional but recommended)

```bash
timedatectl set-timezone 'America/Chicago'
```

If you are unsure about the timezone, run the following command to list available timezones:

```bash
timedatectl list-timezones
```

**Verify date with:**

```bash
date
```

##### Optionally install `ntp` sync

```bash
yum -y install ntp
```

This will allow server to automatically correct its system clock to align
with the global servers.

##### Start and Enable NTP

```bash
systemctl start ntpd && systemctl enable ntpd
```

## Install the `epel-release`

```bash
yum -y install epel-release
```

## Setup Basic Firewall

##### Start and enable the firewall

```bash
systemctl start firewalld
systemctl enable firewalld
```

##### Choose a port to shell into (optional but recommended)

By default, the SSH port is 22. It is highly recommended to change this
to something else however. Changing this value will not make the server
more secure, but it will help stop many automated attacks and make it harder
to guess what port SSH is accessible through.

> In other words, a little security through obscurity.

_Only run the following commands if you are changing the SSH port._

Replace `22` with your chosen port

```bash
firewall-cmd --add-port=22/tcp --zone=public --permanent
firewall-cmd --reload
```

Remember this number as it will be used later.

## Create your shell user

This is optional but highly recommended.

Typically, it is better to disable root login and not perform tasks as the root user. For this reason,
we need to create another user we can shell into the server with and perform admin tasks with.

In the following commands, replace `example_user` with your username.

```bash
useradd example_user && passwd example_user
```

Follow the prompts to create a password for this new user. Once the user has been created, the
user account needs to be placed in the `wheel` group to be able to use `sudo` for commands
that require elevated permission.

```bash
usermod -aG wheel example_user
```

## Harden Server

This is optional but highly recommended.

We will need to edit the `sshd_config` file for this step:

```bash
nano /etc/ssh/sshd_config
```

##### Change

Only change the first line if you changed your port earlier, and change `22` to the port you chose.

```bash
From: #Port 22 | To: Port 22
From: PermitRootLogin yes | To: PermitRootLogin no
```

The following changes are optional but recommended:

```bash
From: #AddressFamily any | To: AddressFamily inet
From: #LoginGraceTime 2m | To: LoginGraceTime 1m
From: #ClientAliveInterval 0 | To: ClientAliveInterval 600
From: #ClientAliveCountMax 3 | To: ClientAliveCountMax 0
```

##### Add

Change `example_user` to your shell user name

```bash
AllowUsers example_user
```

- Save and exit

##### Run

```bash
systemctl restart sshd
```

In a **new** terminal window, verify that the `root` user cannot login anymore remotely. If
you changed your SSH port, also verify that port `22` can not be used to access the system via SSH.

## Create SSH Key Pair

This is completely optional, but for added security, you can generate an
SSH key pair and disable password login to the server. If multiple computers
will be used to access the server, you might not want to do this as every computer will need a copy of the public key plus the passphrase.

### Option 1

##### Run

```bash
ssh-keygen -t rsa
```

A prompt will appear to specify a directory to save in; just hit enter for the default.
Now enter a passphrase for the key and re-enter.
It should say something like `Your identification key has been saved in ...`

##### Modify permissions for SSH

```bash
chmod 700 ~/.ssh
```

##### Modify permissions for new key

```bash
chmod 600 ~/.ssh/id_rsa
```

##### Copy the public key (id_rsa.pub) to the server and install it to the `authorized_keys` list

```bash
cat id_rsa.pub >> ~/.ssh/authorized_keys
```

Only run the following if you have SELINUX enabled

```bash
restorecon -Rv ~/.ssh
```

Now download the private key and import into your SSH client.

### Option 2

Use [PUTTyGEN](https://www.ssh.com/ssh/putty/windows/puttygen) to create the public/private keys:

Then on the server, create the `.ssh` directory:

```bash
mkdir ~/.ssh
```

Create a new `authorized_keys` file:

```bash
nano ~/.ssh/authorized_keys
```

Add the generated public key to this file

Set permissions for the public key directory and the key file itself:

```bash
chmod 700 -R ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

To login, import the private key and passphrase into your SSH client.

#### Now disable password authentication

##### Run

```bash
nano /etc/ssh/sshd_config
```

##### Change

```bash
From: PasswordAuthentication yes | To: PasswordAuthentication no
```

Save and exit

##### Run

```bash
systemctl restart sshd
```

## Configure Hostname

If you do not have a domain, skip this step.

Replace `example.com` with your domain name.

```bash
hostnamectl set-hostname example.com --static
```

## Setup FTP

In order to use FTP, we will need to install `vsftpd` and create a dedicated ftp user.
This user will also be used to own the directory where the application will be served from.

##### Run

```bash
yum -y install vsftpd
```

##### Add new ftp user account

Replace `example_user` with your user name.

```bash
useradd example_user && passwd example_user
```

Follow the prompts to set a password for the new user.

Now we need to edit some configuration settings for `vsftpd`

```bash
nano /etc/vsftpd/vsftpd.conf
```

##### Change

```bash
From: anonymous_enable=YES | To: anonymous_enable=NO
From: #chroot_local_user=YES | To: chroot_local_user=YES
From: listen_ipv6=YES | To: #listen_ipv6=YES
From: listen=NO | To: listen=YES
```

##### Add

```bash
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
```

Save and exit

Now add the following firewall rules:

```bash
firewall-cmd --add-port=20/tcp --zone=public --permanent
firewall-cmd --add-port=20/udp --zone=public --permanent
firewall-cmd --add-port=21/tcp --zone=public --permanent
firewall-cmd --add-port=21/udp --zone=public --permanent
firewall-cmd --add-port=40000-40100/tcp --zone=public --permanent
firewall-cmd --add-port=40000-40100/udp --zone=public --permanent
firewall-cmd --reload
```

Now enable `vsftpd`

```bash
systemctl start vsftpd && systemctl enable vsftpd
```

## Install MariaDB

First, we need to add `mariadb` to the repo list.

##### Run

```bash
nano /etc/yum.repos.d/MariaDB.repo
```

##### Add

```bash
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.3.8/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

- Ensure you have the latest version listed here: http://yum.mariadb.org/
- Save and exit

##### Run

```bash
yum -y install mariadb mariadb-server
systemctl start mariadb && systemctl enable mariadb
```

Now that `mariadb` is installed and enabled, we need to configure it:

##### Run

```bash
mysql_secure_installation
```

Make sure you answer `y` to all the prompts.

Now we need to bind the server's external ip address to `mysqld`:

```bash
nano /etc/my.cnf
```

##### Add

Replace `00.00.00.00` with your server's external ip address.

```bash
[mysqld]
bind-address=00.00.00.00
```

Save and exit

##### Run

```bash
systemctl restart mariadb
```

Now we need to allow `mariadb` through the firewall:

```bash
firewall-cmd --add-port=3306/tcp --zone=public --permanent
firewall-cmd --reload
```

## Setup Remote DB Access

Run the following command to login to mysql server:

```bash
mysql -u root -p
```

When prompted for a password, it should be blank. You should also be prompted to set a password for the
root user, which should be done at this time.

Since we disabled root login earlier, we need to create a user we can connect to the database remotely with:

Replace `example_user` and `example_password` with your username and password.

```bash
GRANT ALL ON *.* TO 'example_user'@'%' IDENTIFIED BY 'example_password' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

## Install Nginx and PHP

##### Run

```bash
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
```

Before running the following command, ensure that you are installing the latest version of PHP, as it might not be 7.2 anymore.

```bash
yum -y install nginx php72w-fpm php72w-bcmath php72w-gd php72w-mbstring php72w-xmlrpc php72w-mysql php72w-pdo php72w-pecl-imagick php72w-xml
```

##### Verify PHP version and installation

```bash
php -v
```

Add the following firewall rules to allow your application to be served:

```bash
firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=443/tcp --zone=public --permanent
firewall-cmd --reload
```

## Configure Nginx

We need to edit the `nginx.conf` file for this step:

```bash
nano /etc/nginx/nginx.conf
```

Empty the contents of this file. This can easily be done in the `nano` editor by using `ctrl + k`.

##### Add

Replace `example_user` with your **ftp** user account.

```bash
user example_user;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    gzip on;
    gzip_comp_level 3;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain application/x-javascript text/xml text/css application/xml;

    client_max_body_size 64M;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
```

Save and exit

## Configure Site Server Block

We need to create a server block to in order to serve the site. Replace `example` with your site (domain) name.

```bash
nano /etc/nginx/conf.d/example.conf
```

##### Add

- Replace `example_user` with your **ftp** user account.
- Replace `example.com` with your domain name.
- You can also optionally add your server's external IP address on the `server_name` line.

```bash
server {
    listen     80;

    server_name  www.example.com example.com;
    root         /home/example_user/public_html/public;

    access_log  /home/example_user/logs/access.log;
    error_log  /home/example_user/logs/error.log;

    client_max_body_size 1024M;
    index index.php index.html;

    location /favicon.ico {
        access_log off;
        expires max;
    }

    location /robots.txt {
        access_log off;
        expires max;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
        access_log        off;
        expires           max;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        client_max_body_size 1024M;
    }

    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
}
```

Save and exit

Before we can start and enable `nginx`, we need to create the following directories
on the server:

- `/home/example_user/public_html/logs`
- `/home/example_user/public_html/public`

In the above, `example_user` is your ftp user account's directory. It is recommended
that use FTP to create these directories with your ftp user because the FTP user needs to be the **owner**
of **everything** in this directory. You can always use `chown` if you didn't
create these directories with your ftp user account.

Now we need to start and enable `nginx`.

```bash
systemctl start nginx && systemctl enable nginx
```

## Configure PHP-FPM

##### Run

```bash
nano /etc/php-fpm.d/www.conf
```

##### Change

Replace `example_user` with your **ftp** user account.

```bash
From: user = apache | To: user = example_user
From: group = apache | To: group = example_user
From: listen = 127.0.0.1:9000 | To: listen = /run/php-fpm/www.sock
From: ;listen.owner = nobody | To: listen.owner = example_user
From: ;listen.group = nobody | To: listen.group = example_user
```

Save and exit

## Configure PHP

These configuration changes are completely optional, but can be useful.

##### Run

```bash
nano /etc/php.ini
```

##### Change

```bash
From: upload_max_filesize = 2M | To: upload_max_filesize = 64M
From: memory_limit = 128M | To: memory_limit = 512M
From: ;cgi.fix_pathinfo=1 | To: cgi.fix_pathinfo=0
```

Save and exit

## Start and Enable PHP-FPM

##### Run

```bash
systemctl start php-fpm && systemctl enable php-fpm
```

We also need to give the **ftp** ownership of the following:

Replace `example_user` with your **ftp** user account.

```bash
chown -R example_user /var/lib/php
chown -R example_user /var/lib/nginx
chown -R example_user /var/log/php-fpm
```

## Test PHP Installation

Create an `index.php` file with the following code and upload
it to `/home/example_user/public_html/public`, where `example_user`
is your **ftp** user account:

```html
<?php phpinfo(); ?>
```

## Install SSL Certificate

Skip this if you do not have a domain pointed to the server's IP address.

##### Run

```bash
yum -y install yum-utils
yum -y install certbot-nginx
certbot --nginx
```

Follow the prompts from the `certbot --nginx` command.

For auto-renewal, the following cron job needs to be added:

##### Run

```bash
export VISUAL=nano; crontab -e
```

##### Add

```bash
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew
```

Save and exit

This will check twice a day for certs that need to be renewed.

## Install Composer

```bash
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
```

## Install Node and NPM

If you want the latest versions of Node.js and NPM, run the following commands:

```bash
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
yum -y install nodejs
```

Make sure you are installing the latest version of Node.js by visiting this link:
https://nodejs.org/en/download/package-manager/#enterprise-linux-and-fedora

##### Verify Node.js version

```bash
node -v
```

##### Verify NPM version

```bash
npm -v
```

Verify you have the latest version of npm by visiting: https://docs.npmjs.com/getting-started/installing-node#3-update-npm

If you need to update NPM, run the following command:

```bash
npm install npm@latest -g
```
