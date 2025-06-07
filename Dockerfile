FROM php:8.3-apache

USER root

RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    wget 

RUN docker-php-ext-install pdo pdo_sqlite

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug
    
COPY ./install-composer.sh ./

RUN sh ./install-composer.sh && rm ./install-composer.sh

RUN apt-get purge -y g++ \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY ./php.ini /usr/local/etc/php/

# Suppress Apache "ServerName" warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN groupadd -g 1234 customgroup && \
    useradd -m -u 1234 -g customgroup leon

USER leon

WORKDIR /var/www/html
