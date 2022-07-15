#!/bin/bash
set -e

# stack mostly sends to stderr
if ! stackResult="$(stack --resolver ghc-$(ghc --print-project-version) new myproject 2>&1 > /dev/null)"; then
	case "$stackResult" in
		*"Unable to load global hints for"*)
			echo >&2 'skipping; stack does not yet support this Haskell version'
			exit 0
			;;
		*)
			echo >&2 'error: stack failed:'
			echo >&2 "$stackResult"
			exit 1
			;;
	esac
fi

cd myproject
stack run 2> /dev/null
