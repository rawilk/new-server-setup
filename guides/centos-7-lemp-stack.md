# New Server Setup

This guide assumes a CentOS 7 linux distro and you are setting a LEMP stack up. It also assumes you know how to point a domain
name to your server's IP address. For best results, complete guide from top to bottom.

If you are familiar with stack scripts, you can automate the entire process by using this stack script: https://www.linode.com/stackscripts/view/332081.
The stack script does exactly what this guide is doing, but it automates it for you. I actually recommend using it
because it is much faster and there is less chance for errors.

## Disable SELinux

SELinux can make the server more secure, but it can be difficult to configure and maintain. For that reason, I usually
disable it, or at least set the mode to `permissive`.

**Run**

```bash
sestatus
```

If it says that SELinux is enabled and enforcing, run the following commands:

```bash
setenforce 0
truncate -s 0 /etc/sysconfig/selinux

# Run as single command
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
```

Now you should reboot the server to disable SELinux. You can wait to the end, but you might as well do it now.
If after rebooting the server, it still says SELinux is enabled and enforcing, just run `setenforce 0` to put
it in `permissive` mode.

## Update yum and install epel-release

```bash
yum -y update
yum -y install epel-release
```

## Configure Hostname

If you do not have a domain, skip this.

Replace `example.com` with your domain name.

```bash
hostnamectl set-hostname example.com --static
```

For this next part, you will need your server's IPv4 and IPv6 addresses.

To get your **IPv4** address, run this command:

```bash
hostname -I | cut -f1 -d' '
```

To get your **IPv6** address, run this command:

```bash
hostname -I | cut -f2 -d' '
```

Now run the following commands to update your `/etc/hosts` file:

```bash
echo ipv4 example.com example >> /etc/hosts
echo ipv6 example.com example >> /etc/hosts
```

- Replace `ipv4` and `ipv6` with your ipv4 and ipv6 address respectively
- Replace `example.com` with your domain name
- Replace `example` with your domain name without the `.com` part

## Set the Server Timezone

It is generally a good idea to set the server's timezone, although completely optional.

**Run**

```bash
timedatectl set-timezone "America/Chicago"
```

Replace `America/Chicago` with your timezone.

If you are unsure about the timezone, run the following command to list available timezones:

```bash
timedatectl list-timezones
```

**Verify date with:**

```bash
date
```

To keep the server's date and time in sync, you can optionally install `ntp`:

```bash
yum -y install ntp
```

Now the service needs to be enabled by running the following commands:

```bash
systemctl start ntpd
systemctl enable ntpd
```

## Create a SUDO user.

It's considered a bad practice to log in as root and also perform most commands as root. This is where a sudo user
comes in. Run the following command to create your sudo user and also set the password at the same time for them:

```bash
useradd example_user && echo example_password | passwd example_user --stdin
```

- Replace `example_user` with your chosen username
- Replace `example_password` with your chosen password

In order for this user to run elevate their level to run certain commands, they need to be added to the `wheel` group:

```bash
usermod -aG wheel example_user
```

Again, replace `example_user` with your sudo user's username.

## Harden Server

**Change SSH Port**

By default, the port the server listens to for SSH connections is 22. If you change this value, it will **not**
make the server more secure, but it will help stop many automated attacks and make it harder to guess what port
SSH is accessible through.

> In other words, a little security through obscurity.

If you would like to change the port the server listens to for SSH connections, you can run the following command:

```bash
sed -i -e "s/#Port 22/Port SSH_PORT/" /etc/ssh/sshd_config
```

Replace `SSH_PORT` with your chosen port number, just be sure that is not in use already by the server.

If you have SELinux enabled, you will also need to run the following command:

```bash
semanage port -a -t ssh_port_t -p tcp SSH_PORT
```

Again, replace `SSH_PORT` with your chosen port.

**Disable Root Login**

It is considered good practice to disable root login. To do this, run the following commands:

```bash
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
```

**Disable SSH password login**

For added security, you can disable password logins to the server via SSH. To do this, you will need to generate
a private/public key pair and add the public key to the server.

Follow these steps to generate your keys:

1. In a terminal on your **local** machine, run this command:

```bash
ssh-keygen
```

**Optional:** to increase the security of your key, increase the size the the `-b` flag. The minimum value is 768
bytes and the default, if you do not use the flag, is 2048 bytes. It is recommended to create a 4096 byte key:

```bash
ssh-keygen -b 4096
```

2. Answer all questions when prompted. You can accept the defaults for everything except the passphrase. When you get
to the passphrase, enter a series of letters and numbers for hte passphrase; it's just like a password.

**Important:** make a note of your passphrase, as you will need it later.

The newly-generated SSH keys are located in the `~/.ssh` directory (if you accepted the defaults). You will find the
private key in the `~/.ssh/id_rsa` file and the public key in the `~/.ssh/id_rsa.pub` file.

3. Add the pubic key to the server for your root and sudo user. You will need to open the `id_rsa.pub` file
and copy the contents of the file. It should be something like `ssh-rsa ...`.

Now run the following commands on your **server** to add the key:

```bash
mkdir -p /root/.ssh
mkdir -p /home/SHELL_USER_NAME/.ssh
echo "SSH_PUB_KEY" > /root/.ssh/authorized_keys
echo "SSH_PUB_KEY" > /home/SHELL_USER_NAME/.ssh/authorized_keys
chmod -R 700 /root/.ssh
chmod -R 700 /home/SHELL_USER_NAME/.ssh
chown -R SHELL_USER_NAME:SHELL_USER_NAME /home/SHELL_USER_NAME/.ssh
```

- Replace `SHELL_USER_NAME` with your sudo user's username
- Replace `SSH_PUB_KEY` with the contents of your **public** key file

Now that the keys have been generated and added to the server, password login can be disabled:

```bash
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
```

For more information on this, please visit: https://www.linode.com/docs/security/authentication/use-public-key-authentication-with-ssh/

**Optional SSH Changes**

```bash
sed -i -e "s/#AddressFamily any/AddressFamily inet/" /etc/ssh/sshd_config
sed -i -e "s/#LoginGraceTime 2m/LoginGraceTime 1m/" /etc/ssh/sshd_config
sed -i -e "s/#ClientAliveInterval 0/ClientAliveInterval 600/" /etc/ssh/sshd_config
sed -i -e "s/#ClientAliveCountMax 3/ClientAliveCountMax 0/" /etc/ssh/sshd_config
```

**Restart sshd service**

In order for these changes to take effect, the following command needs to be run:

```bash
systemctl restart sshd
```

## Configure Firewalld

```bash
systemctl start firewalld
systemctl enable firewalld
```

If you changed your SSH port earlier, you will need to add it to the firewall:

```bash
firewall-cmd --add-port=SSH_PORT/tcp --zone=public --permanent
firewall-cmd --reload
```

Replace `SSH_PORT` with your SSH port

## Install Utils

The following are optional but can be useful:

**yum utils**

```bash
yum -y install yum-utils
```

**htop**

```bash
yum -y install htop
```

**automatic updates**

```bash
yum -y install yum-cron
sed -i -e "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
```

**fail2ban**

```bash
yum -y install fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.loal
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -e "s/backend = auto/backend = systemd/" /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
```

## Setup FTP

In order to use FTP, we will need to install `vsftpd` and create a dedicated ftp user. This user will also be used to own the directory where the application will be served from.

```bash
yum -y install vsftpd
```

**Add new ftp user account**

```bash
useradd FTP_USER_NAME && echo FTP_USER_PASSWORD | passwd FTP_USER_NAME --stdin
```

- Replace `FTP_USER_NAME` with your chosen username
- Replace `FTP_USER_PASSWORD` with your chosen password

Some configuration settings for `vsftpd` will also need to be modified:

```bash
sed -i -e "s/anonymous_enable=YES/anonymous_enable=NO/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/#chroot_local_user=YES/chroot_local_user=YES/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/listen_ipv6=YES/#listen_ipv6=YES/" /etc/vsftpd/vsftpd.conf
sed -i -e "s/listen=NO/listen=YES/" /etc/vsftpd/vsftpd.conf

# Run this as one single command
cat <<EOT >> /etc/vsftpd/vsftpd.conf
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
EOT
```

**Configure firewall for FTP**

```bash
firewall-cmd --add-port=20/tcp --zone=public --permanent
firewall-cmd --add-port=20/udp --zone=public --permanent
firewall-cmd --add-port=21/tcp --zone=public --permanent
firewall-cmd --add-port=21/udp --zone=public --permanent
firewall-cmd --add-port=40000-40100/tcp --zone=public --permanent
firewall-cmd --add-port=40000-40100/udp --zone=public --permanent
firewall-cmd --reload
```

**Start and enable FTP**

```bash
systemctl start vsftpd
systemctl enable vsftpd
```

## Install MariaDB

First, add `mariadb` to the yum repo list.

```bash
touch /etc/yum.repos.d/MariaDB.repo

# Run this as one single command
cat <<EOT >> /etc/yum.repos.d/MariaDB.repo
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.3.9/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOT
```

> Tip: Ensure you have the latest version listed here: http://yum.mariadb.org/

**Install mariadb and start the service**

```bash
yum -y install mariadb mariadb-server
systemctl start mariadb
systemctl enable mariadb
```

Now that `mariadb` is installed, it needs to be configured:

```bash
mysql_secure_installation
```

Answer `y` to all prompts and set a password for the root db user.

**Bind Server IP to MySQL**

```bash
cat <<EOT >> /etc/my.cnf
[mysqld]
bind-address=00.00.00.00
EOT
```

Replace `00.00.00.00` with your server's **public** IP.

**Restart MariaDB**

```bash
systemctl restart mariadb
```

**Configure firewall for MySQL**

```bash
firewall-cmd --add-port=3306/tcp --zone=public --permanent
firewall-cmd --reload
```

## Setup Remote DB Access

Since we disabled root login earlier from `mysql_secure_installation`, a new
user needs to be created in order to connect remotely to the database:

```bash
mysql -u root -pROOT_DB_PASSWORD -e "GRANT ALL ON *.* TO 'DB_USER_NAME'@'%' IDENTIFIED BY 'DB_USER_PASSWORD' WITH GRANT OPTION;FLUSH PRIVILEGES;"
```

- Replace `ROOT_DB_PASSWORD` with your root db password; **do not** add a space after the `-p` flag
- Replace `DB_USER_NAME` with your chosen user name
- Replace `DB_USER_PASSWORD` with your chosen password

## Install PHP and Nginx

```bash
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install nginx php72w-fpm php72w-common php72w-bcmath php72w-gd php72w-mbstring php72w-xmlrpc php72w-mysql php72w-pdo php72w-pecl-imagick php72w-xml
```

**Verify PHP version and installation**

```bash
php -v
```

**Configure firewall**

```bash
firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=443/tcp --zone=public --permanent
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload
```

## Configure Nginx

Run the following commands to configure nginx using the `/etc/nginx/nginx.conf` file:

```bash
truncate -s 0 /etc/nginx/nginx.conf

# Run as a single command
cat <<EOT >> /etc/nginx/nginx.conf
user FTP_USER_NAME;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
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
EOT
```

Replace `FTP_USRE_NAME` with your **ftp** user account

## Configure Site Server Block

A server block needs to be added to serve the application from:

```bash
touch /etc/nginx/conf.d/example.conf
```

Replace `example` with your domain name

```bash
cat <<EOT >> /etc/nginx/conf.d/example.conf
server {
    listen     80;
    server_name  www.example.com example.com;
    root         /home/FTP_USER_NAME/public_html/public;
    access_log  /home/FTP_USER_NAME/logs/access.log;
    error_log  /home/FTP_USER_NAME/logs/error.log;
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
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
        access_log        off;
        expires           max;
    }
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
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
EOT
```

- Replace `example` with your domain name
- Replace `FTP_USER_NAME` with your **ftp** user account

Before the nginx service can be started, the following needs to be created:

```bash
mkdir -p /home/FTP_USER_NAME/logs
mkdir -p /home/FTP_USER_NAME/public_html/public
```

Replace `FTP_USER_NAME` with your **ftp** user account

You can optionally create a test page to test your configuration by running the following:

```bash
touch /home/FTP_USER_NAME/public_html/public/index.php
echo "<?php phpinfo(); ?>" >> /home/FTP_USER_NAME/public_html/public/index.php
```

Again, replace `FTP_USER_NAME` with your **ftp** user account

Since the **ftp** user has to be the **owner** of **everything** here, run the following command:

```bash
chown -R FTP_USER_NAME /home/FTP_USER_NAME
```

Again, replace `FTP_USER_NAME` with your **ftp** user account

**Start and enable nginx**

```bash
systemctl start nginx
systemctl enable nginx
```

## Configure PHP-FPM

```bash
sed -i -e "s/user = apache/user = FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/group = apache/group = FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/listen = 127.0.0.1:9000/listen = \/run\/php-fpm\/www.sock/" /etc/php-fpm.d/www.conf
sed -i -e "s/;listen.owner = nobody/listen.owner = FTP_USER_NAME/" /etc/php-fpm.d/www.conf
sed -i -e "s/;listen.group = nobody/listen.group = FTP_USER_NAME/" /etc/php-fpm.d/www.conf
```

Replace `FTP_USER_NAME` with your **ftp** user account

## Configure PHP

```bash
sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 64M/" /etc/php.ini
sed -i -e "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini
```

## Start and Enable PHP-FPM

```bash
systemctl start php-fpm
systemctl enable php-fpm
```

The **ftp** user account also needs to own the following directories:

```bash
chown -R FTP_USER_NAME /var/lib/php
chown -R FTP_USER_NAME /var/lib/nginx
chown -R FTP_USER_NAME /var/log/php-fpm
```

Replace `FTP_USER_NAME` with your **ftp** user account

## Install SSL Certificate

Skip this if you do not have a domain pointed to the server's IP address.

```bash
yum -y install certbot-nginx
certbot --nginx
```

This will install a free ssl certificate using [letsencrypt](https://letsencrypt.org/).
Follow the prompts from the `certbot --nginx` command.

For auto-renewal, run the following command to add the necessary cron job:

```bash
crontab -l | { cat; echo "0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew"; } | crontab -
```

This will check twice a day for certs that need to be renewed.

To help prevent man-in-the-middle attacks, TLSv1.0 needs to be disabled:

```bash
sed -i -e "s/ssl_protocols TLSv1 TLSv1.1 TLSv1.2;/ssl_protocols TLSv1.1 TLSv1.2;/" /etc/letsencrypt/options-ssl-nginx.conf
```

**Restart nginx**

```bash
systemctl restart nginx
```

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
npm install npm@latest -g
```

**Verify Node.js version**

Make sure you are running the latest version of Node.js by visiting this link: https://nodejs.org/en/download/package-manager/#enterprise-linux-and-fedora

```bash
node -v
```

**Verify NPM version**

Verify you have the latest version of npm by visiting: https://docs.npmjs.com/getting-started/installing-node#3-update-npm
and going to the bottom of the page.

```bash
npm -v
```

## Cleanup

```bash
yum -y remove expect
yum clean all
rm -rf /var/cache/yum
```

With that, everything is finished and the server is ready-to-go.
