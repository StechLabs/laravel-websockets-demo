FROM node:14-alpine AS node
FROM php:7.4-fpm-alpine AS php-builder
LABEL key "Portal-Backend"

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev \
    dpkg \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkgconf \
    re2c \
    zlib \
    wget

RUN apk add --no-cache tzdata && \
    ln -snf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo "Asia/Kolkata" > /etc/timezone && \
    echo "date.timezone = Asia/Kolkata" > /usr/local/etc/php/conf.d/timezone.ini

RUN apk add --no-cache \
    libpng-dev freetype-dev libjpeg-turbo-dev libwebp-dev \
    gmp-dev gettext-dev icu-dev libzip-dev icu-libs

RUN apk update && apk upgrade && \
    apk add --no-cache \
        git zip unzip curl nginx supervisor \
        gmp-dev libintl gettext-dev icu-dev \
        libzip-dev libpng-dev freetype-dev \
        libjpeg-turbo-dev libxml2-dev oniguruma-dev \
        linux-headers libwebp-dev \
        nodejs npm busybox-suid \
        zlib-dev

# Optionally, install other PHP extensions if required
RUN apk add --no-cache bash
RUN apk update && apk add \
    libpng-dev \
    libintl \
    icu-dev \
    libzip-dev \
    gmp-dev \
    zlib-dev

RUN docker-php-ext-install gd gettext intl zip gmp

RUN docker-php-ext-install gd zip mysqli && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd \
    bcmath bz2 exif gettext intl gmp mbstring opcache \
    pdo pdo_mysql shmop sockets sysvmsg sysvsem sysvshm zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apk del --no-cache \
    autoconf gcc g++ make pkgconf re2c libtool libc-dev linux-headers && \
    rm -rf /var/cache/apk/*

WORKDIR /var/www/html
COPY . .

COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/app.conf /etc/nginx/http.d/default.conf
COPY docker/supervisor/supervisord.ini /etc/supervisor.d/supervisord.ini
COPY docker/cron/crontab /etc/crontabs/root
COPY docker/PHP/php.ini /usr/local/etc/php/php.ini
COPY docker/PHP/Docker.sh /usr/local/bin/start.sh

# Set permissions
RUN chmod +x /usr/local/bin/start.sh && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

# Final stage: Production image
FROM php:7.4-fpm-alpine AS production

RUN apk update && apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libwebp-dev \
    zlib-dev \
    libintl \
    icu-dev \
    libzip-dev \
    gmp-dev

WORKDIR /var/www/html

COPY --from=php-builder /var/www/html /var/www/html
COPY --from=php-builder /etc/nginx /etc/nginx
COPY --from=php-builder /etc/supervisor.d /etc/supervisor.d
COPY --from=php-builder /usr/local /usr/local
COPY --from=php-builder /etc/crontabs/root /etc/crontabs/root
COPY --from=php-builder /usr/bin/supervisord /usr/bin/supervisord

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN apk add --no-cache busybox-suid && \
    mkdir -p /var/log/cron && \
    touch /var/log/cron/cron.log

RUN echo 'crond -f -l 8 > /var/log/cron/cron.log &' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/start.sh"]
