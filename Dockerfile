# Use the official PHP image as a base
FROM php:8.2-fpm

# Install dependencies and PHP extensions as root
USER root

# Update the package list and install necessary packages
RUN apt-get update && apt-get install -y \
    libpq-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_pgsql

# Set the working directory
WORKDIR /var/www/html

# Copy the existing application directory contents
COPY . .

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install the PHP dependencies using Composer
RUN composer install

# Install Node.js dependencies and build assets
RUN npm install
RUN npm run build

# Set permissions for storage and cache directories
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Switch to a non-root user
USER www-data
