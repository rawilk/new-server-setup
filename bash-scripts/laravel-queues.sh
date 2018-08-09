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
yum -y update
yum -y install supervisor

echo "Configuring laravel queues"
cat <<EOT >> /etc/supervisord.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $LARAVEL/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=$USERNAME
numprocs=8
redirect_stderr=true
stdout_logfile=$LARAVEL/worker.log
EOT

echo "Starting supervisor"
systemctl start supervisord
systemctl enable supervisord
supervisorctl reread
supervisorctl update
suprvisorctl start laravel-worker:*

echo "Supervisor and laravel queues now running"