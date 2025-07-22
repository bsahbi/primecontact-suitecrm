#!/bin/bash

# Wait for the database to be ready
echo "Waiting for database to be ready..."
until mysqladmin ping -h db -u suiteuser -psuitepass --silent; do
    echo "Database is not ready, waiting..."
    sleep 2
done
echo "Database is ready."

# Ensure bin/console is executable
chmod +x /var/www/html/bin/console

# Ensure apache-servername.conf is writable
chown www-data:www-data /etc/apache2/conf-available/servername.conf
chmod 644 /etc/apache2/conf-available/servername.conf


# Check if SuiteCRM is already installed (config.php exists)
if [ ! -f /var/www/html/public/legacy/config.php ]; then
    echo "Installing SuiteCRM..."
    # Set permissions for writable directories
    # chown -R www-data:www-data /var/www/html
    # find /var/www/html -type d -exec chmod 2775 {} \;
    # find /var/www/html -type f -exec chmod 0644 {} \;
    # chmod -R 2775 /var/www/html/public/legacy /var/www/html/cache /var/www/html/modules /var/www/html/upload

    # Run SuiteCRM silent installation
    ./bin/console suitecrm:app:install -u "admin" -p "pass" -U "suiteuser" -P "suitepass" -H "db" -N "suitecrm" -S "http://localhost:8080/" -d "yes"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        echo "SuiteCRM installation completed successfully."
    else
        echo "SuiteCRM installation failed. Check logs at /var/www/html/logs/install.log."
        exit 1
    fi
else
    echo "SuiteCRM already installed, skipping installation."
fi

# Enable Apache servername configuration
a2enconf servername

# Start Apache in foreground
exec apache2-foreground