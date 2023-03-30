#!/usr/bin/env bash
set -Eeuo pipefail

#
# usage:
#   $ ./pr-urls.sh PR-NUMBER
#   $ ./pr-urls.sh PR-NUMBER IMAGE1 IMAGE2:TAG1 IMAGE3:TAG2
#
#   $ ./pr-urls.sh 12072
#   $ ./pr-urls.sh 12072 hello-world:linux
#   $ ./pr-urls.sh 12072 | xargs -rt bashbrew build
#   $ ./pr-urls.sh 12072 | xargs -rt bashbrew list --uniq
#   $ ./pr-urls.sh 12072 | xargs -rt bashbrew list --uniq | xargs -rt ./test/run.sh
#
# (rough replacement for the old "test-pr.sh" script and its associated complexity)
#

pr="$1"
shift

patch="$(wget -qO- "https://github.com/docker-library/official-images/pull/$pr.patch")"

commit="$(grep <<<"$patch" -oE '^From [0-9a-f]+ ' | tail -1 | cut -d' ' -f2)"

if [ "$#" -eq 0 ]; then
	files="$(grep <<<"$patch" -oE '^[+]{3} b/library/.+' | cut -d/ -f3 | sort -u)"
	set -- $files
fi

for file; do
	echo "https://github.com/docker-library/official-images/raw/$commit/library/$file"
done
