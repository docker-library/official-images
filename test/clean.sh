#!/usr/bin/env bash
set -Eeuo pipefail

docker image ls --digests --no-trunc --format '
	{{- if ne .Tag "<none>" -}}
		{{- .Repository -}} : {{- .Tag -}}
	{{- else if ne .Digest "<none>" -}}
		{{- .Repository -}} @ {{- .Digest -}}
	{{- else -}}
		{{- .ID -}}
	{{- end -}}
' 'librarytest/*' | xargs -rt docker image rm
