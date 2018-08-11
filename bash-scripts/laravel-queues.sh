#!/bin/bash

# Ask for the path to the laravel project
echo -n "Enter the path to your laravel project: "
read LARAVEL

# Ask for the username
echo -n "Enter your application's username (ftp username): "
read USERNAME

# Should migrations be ran?
echo -n "Create job database tables? [y/n] "
read CREATE_TABLES

if [[ $CREATE_TABLES != 'n' ]]; then
    php $LARAVEL/artisan queue:table
    php $LARAVEL/artisan queue:failed-table
    php $LARAVEL/artisan migrate
fi

echo "Installing supervisor"
sudo yum -y update
sudo yum -y install supervisor

echo "Configuring laravel queues"
sudo truncate /etc/supervisord.conf

sudo cat <<EOT >> /etc/supervisord.conf
[unix_http_server]
file = /tmp/supervisor.sock
chmod = 0777
chown= $USERNAME:$USERNAME

[supervisord]
logfile = /tmp/supervisord.log
logfile_maxbytes = 50MB
logfile_backups=10
loglevel = info
pidfile = /tmp/supervisord.pid
nodaemon = false
minfds = 1024
minprocs = 200
umask = 022
user = $USERNAME
identifier = supervisor
directory = /tmp
nocleanup = true
childlogdir = /tmp
strip_ansi = false

[supervisorctl]
serverurl = http://localhost:9001

[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $LARAVEL/artisan queue:work --sleep=3 --tries=3 --daemon
autostart=true
autorestart=true
user=$USERNAME
numprocs=8
redirect_stderr=true
stdout_logfile=$LARAVEL/../logs/worker.log
EOT

# Make the log file and give ownership to the user account
sudo touch $LARAVEL/../logs/worker.log
sudo chown $USERNAME:$USERNAME $LARAVEL/../logs/worker.log

echo "Starting supervisor"
sudo systemctl start supervisord
sudo systemctl enable supervisord
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*

echo "Supervisor and laravel queues now running"