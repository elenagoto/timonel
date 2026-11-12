# Shared image for every PHP project (WordPress, Laravel)
# FrankenPHP (Caddy + PHP) 1.x with PHP 8.4
FROM dunglas/frankenphp:1-php8.4

# PHP extensions for both frameworks:
#   WordPress: mysqli, gd, imagick, exif
#   Laravel:   pdo_mysql, bcmath, pcntl
#   Both:      intl, zip, opcache
RUN install-php-extensions \
    mysqli \
    pdo_mysql \
    gd \
    imagick \
    exif \
    intl \
    zip \
    opcache \
    bcmath \
    pcntl

# Composer (Laravel dependencies; also handy for WordPress plugins/themes)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# git + unzip let Composer install packages; Node.js 24 + npm build
# front-end assets with Vite (WordPress themes, Laravel)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git unzip && \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Increase PHP upload limits
RUN echo "upload_max_filesize = 64M" > /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini

# The project is bind-mounted here by docker-compose.yml
WORKDIR /app

EXPOSE 80

# Start FrankenPHP. The Caddyfile is mounted from the project folder, and
# its web root comes from the WEB_ROOT environment variable (set per
# framework in docker-compose.yml: /app for WordPress, /app/public for Laravel)
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
