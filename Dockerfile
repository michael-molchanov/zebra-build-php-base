FROM composer:latest

LABEL maintainer "Michael Molchanov <mmolchanov@adyax.com>"

USER root

# SSH config.
RUN mkdir -p /root/.ssh
ADD config/ssh /root/.ssh/config
RUN chmod 600 /root/.ssh/config

# Install base.
RUN apk add --update --no-cache \
  bash \
  build-base \
  curl \
  git \
  libffi \
  libffi-dev \
  openssh \
  openssl \
  openssl-dev \
  wget \
  && rm -rf /var/lib/apt/lists/*

# PHP modules.
RUN set -xe \
  && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    libedit-dev \
    libxml2-dev \
    openssl-dev \
    sqlite-dev \
    autoconf \
    subversion \
    freetype-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libbz2 \
    bzip2-dev \
    libstdc++ \
    libxslt-dev \
    openldap-dev \
    make \
    unzip \
  && export CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS" \
  && docker-php-source extract \
  && cd /usr/src/php \
  && docker-php-ext-install bcmath mcrypt zip bz2 mbstring pcntl xsl \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  && docker-php-ext-configure ldap --with-libdir=lib/ \
  && docker-php-ext-install ldap \
  && docker-php-source delete \
  && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
    	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    	| sort -u \
    	| xargs -r apk info --installed \
    	| sort -u \
    )" \
  && apk add --no-cache --virtual .php-rundeps $runDeps \
  && apk del .build-deps
