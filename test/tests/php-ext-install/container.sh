#!/bin/sh
set -e

docker-php-ext-install pdo_mysql 2>&1
php -r 'exit(extension_loaded("pdo_mysql") ? 0 : 1);'
grep -q '^extension=' /usr/local/etc/php/conf.d/*pdo_mysql*.ini

docker-php-ext-install opcache 2>&1
php -r 'exit(extension_loaded("Zend OPcache") ? 0 : 1);'
grep -q '^zend_extension=' /usr/local/etc/php/conf.d/*opcache*.ini
