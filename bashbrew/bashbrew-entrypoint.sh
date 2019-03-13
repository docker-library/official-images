#!/bin/sh
set -e

if [ "${1#-}" != "$1" ]; then
	set -- bashbrew "$@"
fi

# if our command is a valid bashbrew subcommand, let's invoke it through bashbrew instead
# (this allows for "docker run bashbrew build", etc)
if bashbrew "$1" --help > /dev/null 2>&1; then
	set -- bashbrew "$@"
fi

exec "$@"
