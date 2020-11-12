# Docker

A documentation generator built on the foundations of [Docco](http://jashkenas.github.com/docco/) and [Docco-Husky](https://github.com/mbrevoort/docco-husky).

The support available in Docco and Docco-Husky for larger projects consisting of many hundreds of script files was somewhat lacking, so I decided to create my own.

Take a look at this project's [public page](http://jbt.github.com/docker) for an example of what it can do.

## Installation

Simple: `npm install -g docker`

## Usage

```sh
$ docker [options] [files ...]
```

Available options are:

 * `-i` or `--input_dir`: Path to input source directory. Defaults to current directory.
 * `-o` or `--output_dir`: Path to output doc directory. Defaults to `./doc`.
 * `-u` or `--updated_files`: If present, only process files that hav been changed.
 * `-c` or `--colour_scheme` (yes, I'm British): Colour scheme to use. Colour schemes are as below.
 * `-I` or `--ignore_hidden`: Ignore files and directories whose names begin with `.` or `_`.
 * `-w` or `--watch`: Keep the process running, watch for changes on the directory, and process updated files.
 * `-s` or `--sidebar`: Whether or not the sidebar should be opened by default in the output (defaults to yes, can be yes, no, true, false). Value `disable` will disable the sidebar entirely in the output.
 * `-x` or `--exclude`: Comma-separated list of paths to exclude. Supports basic `*` wildcards too.
 * `-n` or `--line-number`: Include line numbers in the output (default is off)
 * `-m` or `--multi_line_only`: Whether to process _only_ multi-line comments. (Defaults to false)
 * `--js`: Specify a comma-separated list of extra javascript files (relative to the current dir) to include
 * `--css`: Same as for `--js` but for CSS files
 * `--extras`: Comma-separated list of optional extras to activate (see below)

If no file list is given, docker will run recursively on every file in the current directory

Any of the files given can also be directories, in which case it will recurse into them.

Folder structure inside the input directory is preserved into the output directory and file names are simply appended `.html` for the doc file

## Examples

If you haven't installed with `-g` specified, replace `docker` with something like `$(npm root)/docker/docker` in all of the examples below.

### Process every file in the current directory into "doc"

```sh
$ docker
```

### Process files in "src" to "documents"

```sh
$ docker -i src -o documents
```
or:
```sh
$ docker -o documents src
```
or:
```sh
$ docker -o documents src/*
```

Note that in the first example, the contents of `src` will be mapped directly into `documents` whereas in the second and third
examples, the files will be created inside `documents/src`

### Generate Docker docs

This is the command I use to generate [this project's documentation](http://jbt.github.com/docker).

 * Output to a directory on the `gh-pages` branch of this repo
 * Use the "manni" colour scheme
 * Show the sidebar by default
 * Ignore files starting with `_` or `.`
 * Only process updated files
 * Exclude the node_modules directory
 * Watch the directory for further changes as the code is updated.
 * Include the File Search extra

```sh
$ docker -o ../docker_gh-pages -c atelier-cave.light -s yes -I -u -x node_modules -w --extras fileSearch
```

## Extras

The output of Docker is designed to be fairly lightweight, so doesn't include much other than the bare
minimum to power the basic features. Optional extras like file searching and line jumping are therefore
contained in there own files and can be turned on by a specific flag.

If you're viewing this on GitHub, take a look [here](/jbt/docker/tree/master/extras); if you're looking
at the Docker output, look [here](extras/README.md), for further explanation.



## Colour Schemes

These are the styles available in `highlight.js`. See the [highight.js demo](https://highlightjs.org/static/demo/) for all available options. You should use the name of the CSS file for this option.

## Important note

All files must be inside the input directory (specified by `-i`) or one of its descendant subdirectories. If they're not then various file paths in the output won't work properly and the file will probably get generated
in the wrong place. Still, it's better than what it used to do, which was to get stuck in an infinite loop.
