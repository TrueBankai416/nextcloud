#!/bin/bash
set -e

# Wait for Nextcloud to be fully initialized
while [ ! -f /var/www/html/config/config.php ]; do
    echo "Waiting for Nextcloud to initialize..."
    sleep 5
done

# Check if notify_push app is installed, if not install it
if ! php /var/www/html/occ app:list | grep -q "notify_push"; then
    echo "Installing notify_push app..."
    php /var/www/html/occ app:install notify_push
fi

# Enable notify_push app
php /var/www/html/occ app:enable notify_push

# Configure notify_push
echo "Configuring notify_push..."
php /var/www/html/occ config:system:set trusted_proxies 1 --value="127.0.0.1"
php /var/www/html/occ config:app:set notify_push base_endpoint --value="ws://localhost:7867"

# Set up the binary path
php /var/www/html/occ config:app:set notify_push binary_path --value="/usr/local/bin/notify_push"

echo "notify_push setup completed!"
