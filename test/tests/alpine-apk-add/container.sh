#!/bin/sh

set -e

# bash is available since https://git.alpinelinux.org/aports/commit/?id=d050e48f55542bf493e4b0bc5327b4cc2a4fef6d
# and a common dependency for many images
apk add --no-cache bash
sh -c "bash --version" | grep -iq "GNU bash"
