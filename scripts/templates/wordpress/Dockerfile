# WordPress with FrankenPHP
FROM dunglas/frankenphp:1-php8.4

# Install WordPress dependencies
RUN install-php-extensions \
    mysqli \
    pdo_mysql \
    gd \
    zip \
    intl \
    opcache \
    exif \
    imagick

# Install Node.js and npm (Debian-based)
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Increase PHP upload limits
RUN echo "upload_max_filesize = 64M" > /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 80

# Start FrankenPHP
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]