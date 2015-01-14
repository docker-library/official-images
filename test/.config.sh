#!/bin/bash
set -e

declare -A imageIncludeTests=()
imageIncludeTests[python]=''
imageIncludeTests[python]+='python'
imageIncludeTests[python]+=' other-python'
imageIncludeTests[python-onbuild]+=''
imageIncludeTests[python-onbuild]+='py-onbuild'
imageIncludeTests[python:3]+=''
imageIncludeTests[python:3]+='py-3'

declare -A globalExcludeTests=()
globalExcludeTests[utc_hello-world]=1

declare -A globalIncludeTests=()
globalIncludeTests[utc]=''
globalIncludeTests[many]='debian ... ubuntu'
