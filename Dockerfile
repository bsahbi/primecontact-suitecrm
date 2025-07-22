# Dockerfile
FROM mcr.microsoft.com/devcontainers/php:8.1

# Update apt cache
RUN apt-get update

# Install required system packages
RUN apt-get install -y \
    git unzip zip curl \
    libicu-dev libxml2-dev libpng-dev libonig-dev libzip-dev libpq-dev \
    libfreetype6-dev libldap2-dev libjpeg-dev libxpm-dev libwebp-dev \
    libkrb5-dev libssl-dev

# Configure PHP extensions before building them
RUN docker-php-ext-configure ldap  \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Build and install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql zip intl gd xml ldap

# Clean up apt cache to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

WORKDIR /var/www/html

# ✅ Correct: copy only suiteCRM source
COPY ./ /var/www/html 

RUN git config --global --add safe.directory /var/www/html


ENV APP_ENV=prod
ENV APP_DEBUG=0

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    composer config --global process-timeout 1200 && \
    composer install --no-dev --optimize-autoloader --no-interaction

RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Install Node.js (v18 LTS includes Corepack)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

RUN corepack enable && corepack prepare yarn@4.5.1 --activate

WORKDIR /var/www/html/extensions/Frontend
RUN yarn install && yarn build

WORKDIR /var/www/html

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

COPY docker/php.ini /usr/local/etc/php/php.ini