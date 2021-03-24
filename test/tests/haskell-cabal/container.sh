#!/bin/bash
set -e

cabal update
cabal install --lib hashable
