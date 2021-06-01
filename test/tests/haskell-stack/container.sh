#!/bin/bash
set -e

# stack mostly sends to stderr
stack --resolver ghc-$(ghc --print-project-version) new myproject 2> /dev/null
cd myproject
stack run 2> /dev/null
