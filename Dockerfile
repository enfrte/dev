FROM php:8.4-apache

RUN docker-php-ext-install pdo pdo_sqlite

RUN pecl install -o -f xdebug-3.4.3 \
    && docker-php-ext-enable xdebug

# Copy composer installable
COPY ./install-composer.sh ./

# Copy php.ini
COPY ./php.ini /usr/local/etc/php/

# Cleanup packages and install composer
RUN apt-get purge -y g++ \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && sh ./install-composer.sh \
    && rm ./install-composer.sh

# Change the current working directory
WORKDIR /var/www/html

# Change the owner of the container document root
RUN chown -R $USER:$USER /var/www/html
