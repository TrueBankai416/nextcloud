#!/bin/bash
set -e

echo "Starting notify_push initialization..."

# Wait for Nextcloud to be fully initialized
while [ ! -f /var/www/html/config/config.php ]; do
    echo "Waiting for Nextcloud to initialize..."
    sleep 5
done

# Wait a bit more for Nextcloud to be fully ready
sleep 10

# Setup notify_push
echo "Setting up notify_push..."
su -p www-data -s /bin/bash -c '/setup-notify-push.sh'

echo "notify_push initialization completed!"

# Keep the process running (supervisord expects it to stay running)
tail -f /dev/null
