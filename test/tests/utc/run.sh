#!/bin/bash
set -e

docker run --rm --entrypoint date "$1" +%Z
