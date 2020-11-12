#!/bin/sh
basedir=$(dirname "$(echo "$0" | sed -e 's,\\,/,g')")

case `uname` in
    *CYGWIN*|*MINGW*|*MSYS*) basedir=`cygpath -w "$basedir"`;;
esac

if [ -x "$basedir/node" ]; then
  "$basedir/node"  "$basedir/../watchr/bin/watchr" "$@"
  ret=$?
else 
  node  "$basedir/../watchr/bin/watchr" "$@"
  ret=$?
fi
exit $ret
