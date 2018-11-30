#!/bin/bash
set -e

cabal new-update
cabal new-install --lib hashable
