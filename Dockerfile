FROM php:7.3.2-fpm as base
MAINTAINER iamsujun "iamsujun@gmail.com"

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更新阿里云版本包源
RUN echo "deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib" > /etc/apt/sources.list \
&& echo "deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.aliyun.com/debian-security stretch/updates main" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.aliyun.com/debian-security stretch/updates main" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y \
    git \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    graphviz \
    librdkafka-dev \
    && docker-php-ext-install gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install sockets \
    && docker-php-ext-install pcntl
#    && rm -r /var/lib/apt/lists/*

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install swoole && docker-php-ext-enable swoole

#tideways php xhprof
ENV XHPROF_VERSION 5.0-beta3
RUN curl -L -o /tmp/php-xhprof.tar.gz https://codeload.github.com/tideways/php-xhprof-extension/tar.gz/v$XHPROF_VERSION \
    && tar xfz /tmp/php-xhprof.tar.gz \
    && rm -r /tmp/php-xhprof.tar.gz \
    && mkdir -p /usr/src/php/ext \
    && mv php-xhprof-extension-$XHPROF_VERSION /usr/src/php/ext/tideways-xhprof \
    && docker-php-ext-install tideways-xhprof \
    && rm -rf /usr/src/php

#rdkafka
ENV RDKAFKA_VERSION 3.0.5
RUN curl -L -o /tmp/rdkafka.tgz http://pecl.php.net/get/rdkafka-$RDKAFKA_VERSION.tgz \
    && tar xfz /tmp/rdkafka.tgz \
    && rm -r /tmp/rdkafka.tgz \
    && mkdir -p /usr/src/php/ext \
    && mv rdkafka-$RDKAFKA_VERSION /usr/src/php/ext/rdkafka \
    && docker-php-ext-install rdkafka \
     && rm -rf /usr/src/php

#FROM base as composer
ENV COMPOSER_HOME /tmp
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
ENV PATH $COMPOSER_HOME/vendor/bin:$PATH

RUN git config --global credential.helper cache

#FROM base as work
RUN usermod -u 1000 www-data

WORKDIR /data1/www
