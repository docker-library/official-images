#!/bin/bash
set -e

# do some hacks to strip out onbuilds in a new faked layer
# usage: ./remove-onbuild.sh input-image output-image
#    ie: ./remove-onbuild.sh rails:onbuild librarytest/rails-onbuild-without-onbuild

in="$1"; shift
out="$1"; shift

outImage="${out%%:*}"
outTag="${out#*:}"
[ "$outImage" != "$outTag" ] || outTag='latest'

tmp="$(mktemp -t -d docker-library-test-remove-onbuild-XXXXXXXXXX)"
trap "rm -rf '$tmp'" EXIT

declare -A json=(
	[Size]=0
)
declare -A mappings=(
	[parent]='.Id'
	[created]='.Created'
	[container]='.Container'
	[container_config]='.ContainerConfig'
	[config]='.Config'
	[docker_version]='.DockerVersion'
	[architecture]='.Architecture'
	[os]='.Os'
)
for key in "${!mappings[@]}"; do
	val="$(docker inspect -f '{{json '"${mappings[$key]}"'}}' "$in")"
	json["$key"]="$val"
done
onbuildConfig="$(docker inspect -f '{{json .Config.OnBuild}}' "$in" | sed 's/[]\/$*.^|[]/\\&/g')" # pre-escaped for use within "sed"
json[config]="$(echo "${json[config]}" | sed -r "s/$onbuildConfig/null/g")" # grab the image config, but scrub the onbuilds
jsonString='{'
first=1
for key in "${!json[@]}"; do
	[ "$first" ] || jsonString+=','
	first=
	jsonString+='"'"$key"'":'"${json[$key]}"
done
newId="$(echo "$jsonString" | sha256sum | cut -d' ' -f1)" # lol, this is hacky
jsonString+=',"id":"'"$newId"'"}'
mkdir -p "$tmp/$newId"
echo "$jsonString" > "$tmp/$newId/json"
echo -n '1.0' > "$tmp/$newId/VERSION"
dd if=/dev/zero of="$tmp/$newId/layer.tar" bs=1k count=1 &> /dev/null # empty tar file

cat > "$tmp/repositories" <<EOF
{"$outImage":{"$outTag":"$newId"}}
EOF

docker rmi -f "$out" &> /dev/null || true # avoid "already exists, renaming the old one" from "docker load"
tar -cC "$tmp" . | docker load
