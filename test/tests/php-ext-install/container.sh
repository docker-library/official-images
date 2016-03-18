#!/bin/sh
set -e

docker-php-ext-install pdo_mysql 2>&1
php -r 'exit(extension_loaded("pdo_mysql") ? 0 : 1);'
