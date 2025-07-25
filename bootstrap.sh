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
if [ ! -f /workspace/installed ]; then

    echo "Installing dependencies for SuiteCRM...."
    composer config --global process-timeout 3600 
    composer install --no-dev --optimize-autoloader --no-interaction --verbose || { echo "Composer install failed"; exit 1; }



    echo "Building frontend for SuiteCRM..."
    yarn install
    yarn merge-angular-json
    yarn build
    yarn build:common
    yarn build:extension defaultExt

    echo "Installing SuiteCRM..."
    # Set permissions for writable directories
    # chown -R www-data:www-data /var/www/html
    # find /var/www/html -type d -exec chmod 2775 {} \;
    # find /var/www/html -type f -exec chmod 0644 {} \;
    # chmod -R 2775 /var/www/html/public/legacy /var/www/html/cache /var/www/html/modules /var/www/html/upload

    find . -type d -not -perm 2755 -exec chmod 2755 {} \;
    find . -type f -not -perm 0644 -exec chmod 0644 {} \;
    find . ! -user www-data -exec chown www-data:www-data {} \;
    chmod +x bin/console


    # Run SuiteCRM silent installation
    ./bin/console suitecrm:app:install -u "admin" -p "pass" -U "suiteuser" -P "suitepass" -H "db" -N "suitecrm" -S "http://localhost:8080/" -d "yes"

    # Check if installation was successful
    find . -type d -not -perm 2755 -exec chmod 2755 {} \;
    find . -type f -not -perm 0644 -exec chmod 0644 {} \;
    find . ! -user www-data -exec chown www-data:www-data {} \;
    chmod +x bin/console
    
    if [ $? -eq 0 ]; then
        echo "SuiteCRM installation completed successfully."
        touch /workspace/installed
    else
        echo "SuiteCRM installation failed. Check logs at /var/www/html/logs/install.log."
        rm /workspace/installed
        exit 1
    fi
else
    echo "SuiteCRM already installed, skipping installation."
fi

# Enable Apache servername configuration
a2enconf servername
service apache2 reload

# Start Apache in foreground
exec apache2-foreground