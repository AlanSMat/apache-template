FROM php:8.1-apache as app

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install git, zip, unzip, this is needed for composer
RUN apt-get update && \
    apt-get install -y git zip unzip

RUN set -eux; \
    install-php-extensions mysqli pdo pdo_mysql;

COPY . /var/www/html/
WORKDIR /var/www/html

# Copy virtual host into container
COPY ./apache/sites-enabled/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable rewrite mode
RUN a2enmod rewrite

# allow super user - set this if you use Composer as a
# super user at all times like in docker containers
ENV COMPOSER_ALLOW_SUPERUSER=1

# obtain composer using multi-stage build
# https://docs.docker.com/build/building/multi-stage/
COPY --from=composer:2.4 /usr/bin/composer /usr/bin/composer

COPY ./app/composer.* ./

RUN composer install --prefer-dist --no-dev --no-scripts --no-progress --no-interaction

# run composer dump-autoload --optimize
RUN composer dump-autoload

# Xdebug has different modes / functionalities. We can default to 'off' and set to 'debug'
# when we run docker compose up if we need it
ENV XDEBUG_MODE=debug

# Copy xdebug config file into container
COPY ./php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install xdebug
RUN set -eux; \
	install-php-extensions xdebug

# Start Apache in foreground
CMD ["apache2-foreground"]