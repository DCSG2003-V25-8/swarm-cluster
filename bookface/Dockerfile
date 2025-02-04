FROM httpd:latest

RUN apt-get update -y \
 && apt-get install -y git apache2 libapache2-mod-php php-pgsql net-tools php-memcache

RUN rm -rf /var/www/html/* \
 && git clone https://github.com/hioa-cs/bookface.git \
 && mv ./bookface/code/* /var/www/html
