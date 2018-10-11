FROM php:7-alpine

ARG BUILD_DATE
ARG VCS_REF

ENV COMPOSER_ALLOW_SUPERUSER 1

LABEL Maintainer="Michael <greennyreborn@gmail.com>" \
      Description="Lightweight php 7.2 container based on alpine with Composer installed and swoole 4.2.1 installed." \
      org.label-schema.name="greenny/php72-swoole" \
      org.label-schema.description="Lightweight php 7.2 container based on alpine with Composer installed and swoole 4.2.1 installed." \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version="1.0.0" \
      org.label-schema.vcs-url="https://github.com/greennyreborn/php72-swoole.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.docker.schema-version="1.0"

RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  	&& apk update \
    && apk add --no-cache curl icu libpng libjpeg-turbo libffi-dev \
    && apk add --no-cache --virtual build-dependencies icu-dev libxml2-dev libpng-dev libjpeg-turbo-dev g++ make autoconf \
    && docker-php-source extract \
    && docker-php-ext-install sockets pdo_mysql \
    && docker-php-source delete \
    # install hiredis
    && wget --no-check-certificate -O /tmp/hiredis.gzip https://github.com/redis/hiredis/archive/v0.14.0.zip \
    && unzip /tmp/hiredis.gzip -d /tmp \
    && cd /tmp/hiredis-0.14.0 \
    && make -j && make install \
    # install swoole
    && wget --no-check-certificate -O /tmp/swoole.gzip https://github.com/swoole/swoole-src/archive/v4.2.1.zip \
    && unzip /tmp/swoole.gzip -d /tmp \
    && cd /tmp/swoole-src-4.2.1 \
    && phpize && ./configure --enable-sockets --enable-async-redis \
    && make && make install \
    && docker-php-ext-enable swoole \
    # install composer
    && curl -sS https://install.phpcomposer.com/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    $$ composer config -g repo.packagist composer https://packagist.phpcomposer.com \
    # clean up
    && cd  / && rm -fr /src \
    && apk del build-dependencies \
    && rm -rf /tmp/* 

USER www-data

WORKDIR /var/www
CMD ["php", "-a"]
