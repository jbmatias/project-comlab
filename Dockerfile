FROM php:8.2.18-fpm-alpine

WORKDIR  /var/www

ENV NEW_RELIC_AGENT_VERSION=10.10.0.1

RUN apk update && apk add \
    build-base \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    zip \
    vim \
    unzip \
    git \
    jpegoptim optipng pngquant gifsicle \
    curl     

RUN docker-php-ext-install pdo_mysql zip exif pcntl
RUN docker-php-ext-configure gd  --with-freetype=/usr/include/ --with-jpeg=/usr/include/ 
RUN docker-php-ext-install gd

RUN apk add --update supervisor && rm  -rf /tmp/* /var/cache/apk/*

RUN apk add autoconf && pecl install -o -f redis \
&& rm -rf /tmp/pear \
&& docker-php-ext-enable redis && apk del autoconf

# Copy php configs
COPY ./docker/php.ini /usr/local/etc/php/conf.d/local.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -L https://download.newrelic.com/php_agent/archive/${NEW_RELIC_AGENT_VERSION}/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux.tar.gz | tar -C /tmp -zx \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux/newrelic-install install \
    && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*


COPY ./docker/entrypoint.sh /entrypoint.sh
COPY ./docker/supervisord.conf /etc/
COPY ./docker/conf.d/* /etc/supervisor/conf.d/

RUN chmod +x /entrypoint.sh

RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

RUN chown www:www -R /usr/local/etc/php/conf.d
# Copy existing application directory permissions and content
COPY --chown=www:www . /var/www

# add root to www group
RUN chmod -R ug+w /var/www/storage

RUN touch /var/www/supervisord.log && chmod 666 /var/www/supervisord.log

# Deployment steps
RUN composer install --optimize-autoloader --no-dev

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD ["/entrypoint.sh"]
