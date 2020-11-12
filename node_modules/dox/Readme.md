# Dox
[![Build Status](https://travis-ci.org/tj/dox.svg?branch=master)](https://travis-ci.org/tj/dox)

 Dox is a JavaScript documentation generator written with [node](http://nodejs.org). Dox no longer generates an opinionated structure or style for your docs, it simply gives you a JSON representation, allowing you to use _markdown_ and _JSDoc_-style tags.

## Installation

Install from npm:

    $ npm install -g dox

## Usage Examples

`dox(1)` operates over stdio:

    $ dox < utils.js
    ...JSON...

 to inspect the generated data you can use the `--debug` flag, which is easier to read than the JSON output:

     $ dox --debug < utils.js

utils.js:

```js
/**
 * Escape the given `html`.
 *
 * @example
 *     utils.escape('<script></script>')
 *     // => '&lt;script&gt;&lt;/script&gt;'
 *
 * @param {String} html string to be escaped
 * @return {String} escaped html
 * @api public
 */

exports.escape = function(html){
  return String(html)
    .replace(/&(?!\w+;)/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
};
```

output:

```json
[
  {
    "tags": [
      {
        "type": "example",
        "string": "    utils.escape('<script></script>')\n    // => '&lt;script&gt;&lt;/script&gt;'",
        "html": "<pre><code>utils.escape(&#39;&lt;script&gt;&lt;/script&gt;&#39;)\n// =&gt; &#39;&amp;lt;script&amp;gt;&amp;lt;/script&amp;gt;&#39;\n</code></pre>"
      },
      {
        "type": "param",
        "string": "{String} html string to be escaped",
        "types": [
          "String"
        ],
        "name": "html",
        "description": "string to be escaped"
      },
      {
        "type": "return",
        "string": "{String} escaped html",
        "types": [
          "String"
        ],
        "description": "escaped html"
      },
      {
        "type": "api",
        "string": "public",
        "visibility": "public"
      }
    ],
    "description": {
      "full": "<p>Escape the given <code>html</code>.</p>",
      "summary": "<p>Escape the given <code>html</code>.</p>",
      "body": ""
    },
    "isPrivate": false,
    "ignore": false,
    "code": "exports.escape = function(html){\n  return String(html)\n    .replace(/&(?!\\w+;)/g, '&amp;')\n    .replace(/</g, '&lt;')\n    .replace(/>/g, '&gt;');\n};",
    "ctx": {
      "type": "method",
      "receiver": "exports",
      "name": "escape",
      "string": "exports.escape()"
    }
  }
]
```

This output can then be passed to a template for rendering. Look below at the "Properties" section for details.

## Usage

```

Usage: dox [options]

  Options:

    -h, --help                     output usage information
    -V, --version                  output the version number
    -r, --raw                      output "raw" comments, leaving the markdown intact
    -a, --api                      output markdown readme documentation
    -s, --skipPrefixes [prefixes]  skip comments prefixed with these prefixes, separated by commas
    -d, --debug                    output parsed comments for debugging
    -S, --skipSingleStar           set to false to ignore `/* ... */` comments

  Examples:

    # stdin
    $ dox > myfile.json

    # operates over stdio
    $ dox < myfile.js > myfile.json

```

### Programmatic Usage

``` javascript

var dox = require('dox'),
    code = "...";

var obj = dox.parseComments(code);

// [{ tags:[ ... ], description, ... }, { ... }, ...]

```

## Properties

  A "comment" is comprised of the following detailed properties:

    - tags
    - description
    - isPrivate
    - isEvent
    - isConstructor
    - line
    - ignore
    - code
    - ctx

### Description

  A dox description is comprised of three parts, the "full" description,
  the "summary", and the "body". The following example has only a "summary",
  as it consists of a single paragraph only, therefore the "full" property has
  only this value as well.

```js
/**
 * Output the given `str` to _stdout_.
 */

exports.write = function(str) {
  process.stdout.write(str);
};
```
yields:

```js
description:
     { full: '<p>Output the given <code>str</code> to <em>stdout</em>.</p>',
       summary: '<p>Output the given <code>str</code> to <em>stdout</em>.</p>',
       body: '' },
```

  Large descriptions might look something like the following, where the "summary" is still the first paragraph, the remaining description becomes the "body". Keep in mind this _is_ markdown, so you can indent code, use lists, links, etc. Dox also augments markdown, allowing "Some Title:\n" to form a header.

```js
/**
 * Output the given `str` to _stdout_
 * or the stream specified by `options`.
 *
 * Options:
 *
 *   - `stream` defaulting to _stdout_
 *
 * Examples:
 *
 *     mymodule.write('foo')
 *     mymodule.write('foo', { stream: process.stderr })
 *
 */

exports.write = function(str, options) {
  options = options || {};
  (options.stream || process.stdout).write(str);
};
```

yields:

```js
description:
     { full: '<p>Output the given <code>str</code> to <em>stdout</em><br />or the stream specified by <code>options</code>.</p>\n\n<h2>Options</h2>\n\n<ul>\n<li><code>stream</code> defaulting to <em>stdout</em></li>\n</ul>\n\n<h2>Examples</h2>\n\n<pre><code>mymodule.write(\'foo\')\nmymodule.write(\'foo\', { stream: process.stderr })\n</code></pre>',
       summary: '<p>Output the given <code>str</code> to <em>stdout</em><br />or the stream specified by <code>options</code>.</p>',
       body: '<h2>Options</h2>\n\n<ul>\n<li><code>stream</code> defaulting to <em>stdout</em></li>\n</ul>\n\n<h2>Examples</h2>\n\n<pre><code>mymodule.write(\'foo\')\nmymodule.write(\'foo\', { stream: process.stderr })\n</code></pre>' }
```

### Tags

  Dox also supports JSdoc-style tags. Currently only __@api__ is special-cased, providing the `comment.isPrivate` boolean so you may omit "private" utilities etc.

```js

/**
 * Output the given `str` to _stdout_
 * or the stream specified by `options`.
 *
 * @param {String} str
 * @param {{stream: Writable}} options
 * @return {Object} exports for chaining
 */

exports.write = function(str, options) {
  options = options || {};
  (options.stream || process.stdout).write(str);
  return this;
};
```

yields:

```js
tags:
   [ { type: 'param',
       string: '{String} str',
       types: [ 'String' ],
       name: 'str',
       description: '' },
     { type: 'param',
       string: '{{stream: Writable}} options',
       types: [ { stream: ['Writable'] } ],
       name: 'options',
       description: '' },
     { type: 'return',
       string: '{Object} exports for chaining',
       types: [ 'Object' ],
       description: 'exports for chaining' },
     { type: 'api',
       visibility: 'public' } ]
```

#### Complex jsdoc tags

dox supports all jsdoc type strings specified in the [jsdoc documentation](http://usejsdoc.org/tags-type.html). You can
specify complex object types including optional flag `=`, nullable `?`, non-nullable `!` and variable arguments `...`.

Additionally you can use `typesDescription` which contains formatted HTML for displaying complex types.

```js

/**
 * Generates a person information string based on input.
 *
 * @param {string | {name: string, age: number | date}} name Name or person object
 * @param {{separator: string} =} options An options object
 * @return {string} The constructed information string
 */

exports.generatePersonInfo = function(name, options) {
  var str = '';
  var separator = options && options.separator ? options.separator : ' ';

  if(typeof name === 'object') {
    str = [name.name, '(', name.age, ')'].join(separator);
  } else {
    str = name;
  }
};
```

yields:

```js
tags:
[
  {
    "tags": [
      {
        "type": "param",
        "string": "{string | {name: string, age: number | date}} name Name or person object",
        "name": "name",
        "description": "Name or person object",
        "types": [
          "string",
          {
            "name": [
              "string"
            ],
            "age": [
              "number",
              "date"
            ]
          }
        ],
        "typesDescription": "<code>string</code>|{ name: <code>string</code>, age: <code>number</code>|<code>date</code> }",
        "optional": false,
        "nullable": false,
        "nonNullable": false,
        "variable": false
      },
      {
        "type": "param",
        "string": "{{separator: string} =} options An options object",
        "name": "options",
        "description": "An options object",
        "types": [
          {
            "separator": [
              "string"
            ]
          }
        ],
        "typesDescription": "{ separator: <code>string</code> }|<code>undefined</code>",
        "optional": true,
        "nullable": false,
        "nonNullable": false,
        "variable": false
      },
      {
        "type": "return",
        "string": "{string} The constructed information string",
        "types": [
          "string"
        ],
        "typesDescription": "<code>string</code>",
        "optional": false,
        "nullable": false,
        "nonNullable": false,
        "variable": false,
        "description": "The constructed information string"
      }
    ]
```

### Code

 The `.code` property is the code following the comment block, in our previous examples:

```js
exports.write = function(str, options) {
  options = options || {};
  (options.stream || process.stdout).write(str);
  return this;
};
```

### Ctx

  The `.ctx` object indicates the context of the code block, is it a method, a function, a variable etc. Below are some examples:

```js
exports.write = function(str, options) {
};
```

yields:

```js
ctx:
 { type: 'method',
   receiver: 'exports',
   name: 'write',
   string: 'exports.write()' } }
```

```js
var foo = 'bar';
```

yields:

```js
ctx:
 { type: 'declaration',
   name: 'foo',
   value: '\'bar\'',
   string: 'foo' }
```

```js
function User() {

}
```

yields:

```js
ctx:
 { type: 'function',
   name: 'User',
   string: 'User()' } }
```

### Extending Context Matching

Context matching in dox is done by performing pattern matching against the code following a
comment block. `dox.contextPatternMatchers` is an array of all pattern matching functions,
which dox will iterate over until one of them returns a result. If none return a result,
then the comment block does not receive a `ctx` value.

This array is exposed to allow for extension of unsupported context patterns by adding more
functions.  Each function is passed the code following the comment block and (if detected)
the parent context if the block.

```js
dox.contextPatternMatchers.push(function (str, parentContext) {
  // return a context object if found
  // return false otherwise
});
```

### Ignore

Comments and their associated bodies of code may be flagged with "!" to be considered worth ignoring, these are typically things like file comments containing copyright etc, however you of course can output them in your templates if you want.

```
/**
 * Not ignored.
 */
```

vs

```
/*!
 * Ignored.
 */
```

You may use `-S`, `--skipSingleStar` or `{skipSingleStar: true}` to ignore `/* ... */` comments.

### Running tests

 Install dev dependencies and execute `make test`:

     $ npm install -d
     $ make test

## License

(The MIT License)

Copyright (c) 2011 TJ Holowaychuk &lt;tj@vision-media.ca&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
