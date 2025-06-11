# Use the official PHP 8.3 image with Apache pre-installed
FROM php:8.3-apache

# Declare build arguments
# Check and adjust HOST_UID as needed - Linux: id -u
# Check and adjust HOST_GID as needed - Linux: id -g
ARG HOST_UID=1000 
ARG HOST_GID=1000 

# Switch to root user to perform package installations and system modifications
USER root

# Update package lists and install required system packages
# libsqlite3-dev \     # Development headers for SQLite (needed for PDO SQLite extension)
# wget                 # Utility for downloading files (used by composer installer script)
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    wget 

# Install PHP extensions for PDO and SQLite
RUN docker-php-ext-install pdo pdo_sqlite

# Install and enable Xdebug for debugging support
# Download and build Xdebug via PECL
# Enable the Xdebug extension in PHP
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Copy a local shell script for installing Composer into the container
COPY ./install-composer.sh ./

# Run the Composer installer script and remove it afterwards
RUN sh ./install-composer.sh && rm ./install-composer.sh

# Clean up unnecessary tools and cache to reduce the final image size
# Remove C++ compiler (used during Xdebug install)
# Remove unused packages
# Clean APT cache
# Clean temp files
RUN apt-get purge -y g++ \
    && apt-get autoremove -y \
    && rm -r /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Copy custom PHP configuration into the container
COPY ./php.ini /usr/local/etc/php/

# Suppress Apache "ServerName" warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create a non-root user with specific UID and GID for safer container execution
# Create a group with GID 1234
# Create a user 'leon' with UID 1234 in that group
RUN groupadd -g ${HOST_GID} customgroup && \
    useradd -m -u ${HOST_UID} -g customgroup leon


# Enable mod_rewrite and default site during build
RUN a2enmod rewrite && \
    a2ensite 000-default.conf

# Insert a <Directory> block below the DocumentRoot directive in 000-default.conf
# to explicitly allow .htaccess overrides under /var/www/html
RUN sed -i '/DocumentRoot/a <Directory /var/www/html>\n    AllowOverride All\n</Directory>' /etc/apache2/sites-available/000-default.conf

# Switch to the non-root user for all following commands
USER leon

# Set the working directory inside the container
WORKDIR /var/www/html
