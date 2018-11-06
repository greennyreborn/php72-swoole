FROM php:7-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG SWOOLE_TAG
ARG DESC

ENV COMPOSER_ALLOW_SUPERUSER 1

LABEL Maintainer="Michael <greennyreborn@gmail.com>" \
      Description=$DESC \
      org.label-schema.name="greenny/php72-swoole" \
      org.label-schema.description=$DESC \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version="1.2.3" \
      org.label-schema.vcs-url="https://github.com/greennyreborn/php72-swoole.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.docker.schema-version="1.0"

RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  	&& apk update \
  	&& apk add --no-cache iptables \
    && apk add --no-cache curl icu libpng libjpeg-turbo libffi-dev \
    && apk add --no-cache --virtual build-dependencies icu-dev libxml2-dev libpng-dev libjpeg-turbo-dev g++ make autoconf \
    && docker-php-source extract \
    && docker-php-ext-install sockets pdo_mysql \
    && docker-php-source delete \
    # install swoole
    && swoole_version=$SWOOLE_TAG \
    && wget --no-check-certificate -O /tmp/swoole.gzip https://github.com/swoole/swoole-src/archive/v${swoole_version}.zip \
    && unzip /tmp/swoole.gzip -d /tmp \
    && cd /tmp/swoole-src-${swoole_version} \
    && phpize && ./configure --enable-sockets \
    && make && make install \
    && docker-php-ext-enable swoole \
    # install composer
    && curl -sS https://install.phpcomposer.com/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer config -g repo.packagist composer https://packagist.laravel-china.org \
    # clean up
    && cd  / && rm -fr /src \
    && apk del build-dependencies \
    && rm -rf /tmp/*

USER www-data

WORKDIR /var/www
CMD ["php", "-a"]
