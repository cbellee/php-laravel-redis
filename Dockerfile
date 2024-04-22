FROM php:8.1
RUN apt-get update -y && apt-get install -y openssl zip unzip git

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN docker-php-ext-install pdo
WORKDIR /app
COPY ./src/ /app
RUN composer install

# CMD php artisan serve --host=0.0.0.0 --port=8181
CMD php artisan app:test-redis
# EXPOSE 8181