#!/bin/bash

# Note: This needs to be run as the root user

# Ask for the path to the laravel project
echo -n "Enter the path to your laravel project: "
read LARAVEL

# configure the scheduler to run
crontab -l | { cat; echo "* * * * * cd $LARAVEL && php artisan schedule:run >> /dev/null 2>&1"; } | crontab -

echo "Laravel scheduler is now running for: $LARAVEL"