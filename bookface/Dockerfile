FROM php:8.2-apache

WORKDIR /var/www/html

RUN apt-get update \
 && apt-get install -y git libpq-dev libmemcached-dev zlib1g-dev libevent-dev \
 && pecl install memcache \
 && docker-php-ext-enable memcache
 
RUN docker-php-ext-install pgsql pdo_pgsql pdo

RUN git clone https://github.com/hioa-cs/bookface.git \
 && mv bookface/code/* . \
 && rm -rf bookface \
 && printf "{}" > config.json