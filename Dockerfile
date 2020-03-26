FROM alpine:3.8

ENV php_conf /usr/local/etc/php-fpm.conf
ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_ini_dir /usr/local/etc/php
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

ENV CMS_ENV docker-dev
ENV NGINX_VERSION 1.16.1
ENV DEVEL_KIT_MODULE_VERSION 0.3.0

RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    gcc \
    g++ \
    libc-dev \
    make \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    ca-certificates

# compile openssl, otherwise --with-openssl won't work
RUN set -xe \
	&& OPENSSL_VERSION="1.0.2k" \
	&& cd /tmp \
	&& mkdir openssl \
	&& curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
	&& curl -sL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
	&& tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
	&& cd /tmp/openssl \
	&& ./config \
	&& make depend \
	&& make -j"$(nproc)" \
	&& make install \
	&& rm -rf /tmp/* \
  && ln -s /usr/local/bin/ssl/bin/openssl /usr/local/bin/openssl

# Install PHP
RUN mkdir -p $php_ini_dir/conf.d
ADD scripts/docker-php-* /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-php-source && chmod 755 /usr/local/bin/docker-php-ext-configure && chmod 755 /usr/local/bin/docker-php-ext-enable && chmod 755 /usr/local/bin/docker-php-ext-install

RUN apk upgrade --update \
  && apk add --no-cache \
  readline readline-dev \
  libxml2 libxml2-dev libxml2-utils \
  libxslt libxslt-dev zlib-dev zlib \
  curl curl-dev \
  pcre pcre-dev \
  recode recode-dev \
  mysql-client \
  && mkdir -p /usr/src/php \
	&& curl -SL "https://www.php.net/get/php-5.4.45.tar.gz/from/this/mirror" -o /usr/src/php.tar.gz \
	&& curl -SL "https://www.php.net/get/php-5.4.45.tar.gz/from/this/mirror" -o /usr/src/php.tar.gz.asc \
	&& cd /usr/src \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="$php_ini_dir" \
		--with-config-file-scan-dir="$php_ini_dir/conf.d" \
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		--disable-cgi \
    --with-curl \
		--with-openssl=/usr/local/ssl \
		--enable-mysqlnd \
		--with-mysql \
		--with-readline \
		--with-recode \
		--with-zlib \
	&& make -j"$(nproc)" \
	&& make install \
	&& make clean \
	\
	&& { find /usr/local/bin /usr/local/sbin -type f -exec strip --strip-all '{}' + || true; } \
	\
	&& cd / \
	&& docker-php-source delete



## TODO: Add apk del options to remove unused libraries

CMD ["/bin/sh"]
