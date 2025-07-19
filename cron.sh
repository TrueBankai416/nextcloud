#!/bin/sh
set -eu

# Ensure www-data crontab exists and has proper permissions
if [ ! -f /var/spool/cron/crontabs/www-data ]; then
    echo "Creating crontab for www-data user..."
    echo '*/5 * * * * php /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data
fi

chown www-data:www-data /var/spool/cron/crontabs/www-data
chmod 600 /var/spool/cron/crontabs/www-data

# Start cron daemon
echo "Starting cron daemon..."
exec busybox crond -f -L /dev/stdout
