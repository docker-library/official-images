#!/bin/sh
set -e

docker-php-ext-install pdo_mysql 2>&1
php -d display_errors=stderr -r 'exit(extension_loaded("pdo_mysql") ? 0 : 1);'
grep -q '^extension=' /usr/local/etc/php/conf.d/*pdo_mysql*.ini

# TODO now that opcache is built-in (8.5+), we could use a new zend_extension to test that they're loaded correctly too 🙈
