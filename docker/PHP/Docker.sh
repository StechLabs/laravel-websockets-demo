#!/bin/sh

echo "Running initialization script..."

chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache
composer install --no-interaction --optimize-autoloader

php artisan key:generate
php artisan optimize:clear
php artisan cache:clear
php artisan config:clear

npm install
npm run prod
rm -rf node_modules

apk add nginx
apk add supervisor

echo "Starting Nginx..."
nginx &

echo "Starting PHP-FPM..."
echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf

echo "********************"
echo "| SERVER STARTED   |"
echo "********************"
