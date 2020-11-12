# Optional Docker Extras

This directory contains optional files that can be enabled in Docker output

File stucture in this directory is incredibly simple: for a given extra name
(e.g. `extraName`) create a directory with that name, and one single JavaScript
and one CSS file for the extra (i.e. `extraName/extraName.js`, `extraName/extraName.css`).
This format may change in the future to allow for multiple files or for extending
the functionality of the Docker process itself, but this format will remain supported.

# Current Extras

## fileSearch

Fuzzy string-matching against file names. Once enabled, hit Ctrl/Cmd + P
(&agrave; la Sublime Text 2) to bring up a search field, type some important
characters that should be enough to identify a file, hit return and jump straight
to the file. Alternatively, just start typing and the search field will automatically appear.

## goToLine

Simple option to quickly jump to a particular code line. Just hit Ctrl/Cmd + G and
type a line number into the field to instantly jump to the given line. Currently this
only works when the `--line-numbers` option is used, and only works for code lines
(i.e. it won't allow you to jump to a line with a comment on it)
