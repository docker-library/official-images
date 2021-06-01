#!/usr/bin/env bash
set -Eeuo pipefail

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# do a little extra work to try and find a suitable JDK image (when "xyzjava:1.2.3-jre" first builds, "xyzjava:1.2.3-jdk" isn't published yet :D)
tryJdks=(
	# ideally, we'd just swap the current JRE image to JDK, but that might not exist yet (see above)
	"${image/jre/jdk}"

	# try progressively less specific versions to try and find something that can compile an appropriate ".class" object for use in $image (working our way out from "Java 8" because that's going to be the most compatible)
	"${image%%:*}:8-jdk-slim"
	"${image%%:*}:8-jdk"
	"${image%%:*}:jdk-slim"
	"${image%%:*}:jdk"
	"${image%%:*}:latest"
	'openjdk:8-jdk-slim'
)
jdk=
for potentialJdk in "${tryJdks[@]}"; do
	if docker image inspect "$potentialJdk" &> /dev/null; then
		jdk="$potentialJdk"
		break
	fi
	if docker pull --quiet "$potentialJdk" &> /dev/null; then
		jdk="$potentialJdk"
		break
	fi
done
if [ -z "$jdk" ]; then
	echo >&2 "error: failed to find a suitable JDK image for '$image'!"
	exit 1
fi
if [ "$jdk" != "${tryJdks[0]}" ]; then
	echo >&2 "warning: using '$jdk' instead of '${tryJdks[0]}' (results may vary!)"
fi

# if possible, use "--release" in case $jdk and $image have mismatching Java versions
javac='javac'
if docker run --rm "$jdk" java --help 2>&1 | grep -q -- '--release'; then
	javac='javac --release 8'
fi

newImage="$("$runDir/image-name.sh" librarytest/java-hello-world "$image")"
"$runDir/docker-build.sh" "$testDir" "$newImage" <<EOD
FROM $jdk AS jdk
WORKDIR /container
COPY dir/container.java ./
RUN $javac ./container.java
FROM $image
COPY --from=jdk /container /container
WORKDIR /container
EOD

docker run --rm "$newImage" java -cp . container
