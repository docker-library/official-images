#!/bin/bash
set -e

pip install -q hy
[ "$(hy -c '(-> (+ 2 2) (print))')" = '4' ]

pip install -q sh
[ "$(hy -c '(import [sh [echo]]) (-> (echo 42) (print))')" = '42' ]
