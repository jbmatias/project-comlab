#!/usr/bin/env sh

role=${CONTAINER_ROLE:-app}

if [ "$role" = *"app"* ]; then 
 #App Entry Point

    echo "Running the role \"$role\" ..."
        sed -i -e "s/REPLACE_WITH_REAL_KEY/${NEW_RELIC_LICENSE_KEY}/" \
        -e "s/newrelic.appname[[:space:]]=[[:space:]].*/newrelic.appname=\"${NEW_RELIC_APPNAME}\"/" \
        -e '$anewrelic.daemon.address="172.17.0.1:31339"' \
        $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
    
    php-fpm

elif [ "$role" = "queue" ]; then
 
    echo "Running the role \"$role\" ..."
    php /var/www/artisan queue:work --verbose --tries=3 --timeout=90
 
elif [ "$role" = "scheduler" ]; then
 
    echo "Running the role \"$role\" ..."
    while [ true ]
    do
      php /var/www/artisan schedule:run --verbose --no-interaction & 
      sleep 60
    done

elif [ "$role" = "supervisord" ]; then
 
    echo "Running the role \"$role\" ..."
    supervisord --nodaemon --configuration /etc/supervisord.conf
    
else
    echo "Could not match the container role \"$role\""
    exit 1
fi
