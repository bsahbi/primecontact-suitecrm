FROM suitecrm-base:latest

RUN a2enmod rewrite

WORKDIR /var/www/html

COPY ./ /var/www/html 



ENV APP_ENV=prod
ENV APP_DEBUG=0

RUN composer config --global process-timeout 1200 && \
    composer install --no-dev --optimize-autoloader --no-interaction

RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

RUN corepack enable && corepack prepare yarn@4.5.1 --activate

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

RUN yarn install
RUN yarn merge-angular-json
RUN yarn build
# RUN yarn build:common
RUN yarn build:extension defaultExt

COPY docker/php.ini /usr/local/etc/php/php.ini

COPY apache-servername.conf /etc/apache2/conf-available/servername.conf
RUN chown www-data:www-data /etc/apache2/conf-available/servername.conf && chmod 644 /etc/apache2/conf-available/servername.conf

# RUN ./bin/console suitecrm:app:install -u "admin" -p "pass" -U "suiteuser" -P "suitepass" -H "db" -N "suitecrm" -S "https://localhost:8080/" -d "yes"

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html
RUN chmod +x /var/www/html/bin/console
RUN chmod +x entrypoint.sh
# RUN find /var/www/html -type d -exec chmod 2775 {} \;
# RUN find /var/www/html -type f -exec chmod 0644 {} \;
