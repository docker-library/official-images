#!/bin/sh
set -eu

find /usr/local /opt '(' -name '*.pyc' -o -name '*.pyo' ')' -print -exec false '{}' +
