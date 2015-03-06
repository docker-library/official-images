#!/bin/bash

set -ueo pipefail

docker-php-ext-install pdo_mysql 2>&1
