FROM php:8.4-apache

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        imagemagick \
        libmagickwand-dev \
        zlib1g-dev \
        libpng-dev \
        libzip-dev && \
    pecl install imagick && \
    docker-php-ext-install mysqli gd zip && \
    docker-php-ext-enable imagick mysqli && \
    a2enmod rewrite && \
    printf "upload_max_filesize = 0\npost_max_size = 0\n" > /usr/local/etc/php/conf.d/uploads.ini && \
    rm -rf /var/lib/apt/lists/*

RUN echo '<Directory /var/www/html>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf
