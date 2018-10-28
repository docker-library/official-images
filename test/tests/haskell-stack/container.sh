#!/bin/bash
set -e

# stack mostly sends to stderr
stack new myproject 2> /dev/null
cd myproject
stack config set resolver ghc-$(ghc --print-project-version) 2> /dev/null
stack build 2> /dev/null
