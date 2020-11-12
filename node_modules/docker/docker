#!/usr/bin/env node

// Require all node modules
var path = require('path');
var program = require('commander');

// Require [Docker](src/docker.js)
var Docker = require('./src/docker.js');

// Figure out PWD because it doesn't exist in process.env on windows.
var pwd = path.resolve('.');

var pkg = require('./package.json');

function list(val) {
  return val.split(',');
}

// All program arguments using commander
program
  .version(pkg.version)
  .option('-i, --input_dir [dir]', 'Input directory (defaults to current dir)', pwd)
  .option('-o, --output_dir [dir]', 'Output directory (defaults to ./doc)', path.join(pwd, 'doc'))
  .option('-u, --updated_files', 'Only process files that have been changed')
  .option('-c, --colour_scheme [style]', 'Colour scheme to use (see https://github.com/isagalaev/highlight.js/tree/master/src/styles)')
  .option('-I, --ignore_hidden', 'Ignore hidden files and directories (those starting with . or _)')
  .option('-w, --watch', 'Watch on the input directory for file changes (experimental)')
  .option('-s, --sidebar [state]', 'Whether the sidebar should be open or not by default', 'yes')
  .option('-x, --exclude [pattern]', 'Paths to exclude', false)
  .option('-n, --line-numbers', 'Whether to include line numbers in output', false)
  .option('-m, --multi_line_only', 'Whether to process only multi-line comments', false)
  .option('--js <files>', 'Additional javascript files to include', list)
  .option('--css <files>', 'Additional CSS files to include', list)
  .option('--extras <extras>', 'Bundled extras to include, see extras dir', list)
  .parse(process.argv);


// Super-simple function to test if ann argument is vaguely trueish or falseish.
// Should match `true`, `false`, `0`, `1`, `'0'`, `'1'`, `'y'`, `'n'`, `'yes'`, `'no'`, `'ok'`, `'true'`, `'false'`
function coerceSidebar(input) {
  if (input === 'disable') return input;
  if (input === true || input === false) return input;
  if (typeof input === 'number' || (+input + '' === input + '')) return !!+input;
  input = input.toString();
  return input === '' ? true : /(y(es)?|ok|t(rue)?)/i.test(input);
}

// Put all the options into an object
var opts = {
  inDir: program.input_dir,
  outDir: program.output_dir,
  onlyUpdated: program.updated_files,
  colourScheme: program.colour_scheme,
  ignoreHidden: program.ignore_hidden,
  sidebarState: coerceSidebar(program.sidebar),
  exclude: program.exclude,
  lineNums: program.lineNumbers,
  multiLineOnly: program.multi_line_only,
  js: program.js,
  css: program.css,
  extras: program.extras
};

// Create docker instance
var d = new Docker(opts);

// If no file list is specified, just run on whole directory
if (program.args.length === 0) program.args = [ './' ];

// Set it running.
if (program.watch) {
  d.watch(program.args);
} else {
  d.doc(program.args);
}
