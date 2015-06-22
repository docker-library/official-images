#!/bin/bash
set -e

# We have to eat stderr here because of:
# W: Conflicting distribution: http://http.debian.net rc-buggy InRelease (expected rc-buggy but got experimental)
# W: Conflicting distribution: http://archive.ubuntu.com devel Release (expected devel but got vivid)
# W: Conflicting distribution: http://archive.ubuntu.com devel-updates Release (expected devel-updates but got vivid)
# W: Conflicting distribution: http://archive.ubuntu.com devel-security Release (expected devel-security but got vivid)
apt-get update &> /dev/null

# We have to eat stderr here because of:
# debconf: delaying package configuration, since apt-utils is not installed
apt-get install -y hello &> /dev/null

exec hello
