0.8.1 / 2016-03-29
==================

* Fix: Dox will no longer falsely enter or exit string blocks when encountering an escaped quote or double-quote
* Deps: commander@2.9.0
* Deps: marked@0.3.5

0.8.0 / 2015-05-27
==================

* Fix: Tags with whitespace between the tag start and the previous line ending are now parsed correctly.
* Deps: commander@2.8.1
* Deps: jsdoctypeparser@1.2.0
  - Better compatibility for type declarations, but may result in changes to output with invalid types.

0.7.1 / 2015-04-03
==================

Context parsing has been re-factored into an array of functions that are iterated over until a match is found. This array is exposed as `dox.contextPatternMatchers`, allowing for extension with new contexts without needing to edit the dox source.

* Fix: ES6 classes extended from sub-properties (such as Backbone.View) are now properly matched

0.7.0 / 2015-03-24
==================

* Add context parsing for some ES6 syntax:
  - classes
  - class constructors
  - class methods
  - assignments via `let` or `const`
* Add support for @description tag
* Add context match for returned closure
* Add: Tags without descriptions now have an `html` property containing a markdown parse of the tag's contents
* Fix: more agnostic to code style when parsing contexts (eg, no longer ignores functions without spaces between function name and parenthesis)
* Fix: No longer incorrectly tries to parse strings inside comments, causing large chunks of a file to be ignored.
* Fix: No longer parses double slash in a string literal as being a comment start.
* Deps: commander@2.7.1

0.6.1 / 2014-11-27
==================

* Tag descriptions now contain markdown and obey raw option

0.6.0 / 2014-11-27
==================

* Add complex jsdoc annotations
* Add support for more tags
* Add typesDescription field
* Fix "skipPrefixes incorrectly assumes option.raw=false"
* Fix "White spaces in the tag type string break the parsing of tags"

0.5.3 / 2014-10-06
==================

* Add `--skipSingleStar` option to ignore `/* ... */` comments
* Merge #106: make the other context regex like the general method one

0.5.2 / 2014-10-05
==================

* Support event tags, add `isEvent` parameter to comment object
* Removed obsolete make rules

0.5.1 / 2014-09-07
==================

* Fixed: `*/*` breaks parsing

0.5.0 / 2014-09-04
==================

* Marked options can be set via `dox.setMarkedOptions`
* Comment blocks include `line` and `codeStart` to mark the first line of the comment block and the first line of the code context.
* Ignores jshint, jslint and eslint directives. This can be overridden or added to via the `skipPrefixes` option and the `--skipPrefixes` command line flag, which takes a comma separated list of prefixes.
* The code field trims extra indentation based on the indentation of the first line of code.
* Set the `isConstructor` property when a `@constructor` tag is present and change `ctx.type` to constructor.
* Recognizes the following code contexts:
  - `Foo.prototype.bar;` (property)
  - `Foo.prototype = {` (prototype)
  - `foo: function () {` (method)
  - `foo: bar` (property)
  - `get foo () {` (property)
  - `set foo () {` (property)
* When a comment is present to identify the definition of an object literal, comments for the object's members will include a `ctx.constructor` property identifying the parent object.
* Fixed: Multi-line comments with no space following the star are parsed correctly.
  - Example: `/*comment*/`
* Fixed: A code context of `Foo.prototype.bar = null;` is parsed correctly.
* `@param` tags include an `optional` attribute
* `@returns` is recognized as an alias for `@return`
* Support comments without descriptions (ex: `/** @name Foo **/`)
* Fixed: Crash with the `--api` flag when no headers are generated.
* Fixed: `--api` output includes aliases.

0.4.6 / 2014-07-09
==================

 * do not wrap @example contents with markdown

0.4.5 / 2014-07-09
==================

 * use marked for markdown rendering
 * multiline tags support (@example)
 * support for @template, @property, @define, @public, @private, @protected,
   @lends, @extends, @implements, @enum, @typedef

0.4.4 / 2013-07-28 
==================

 * add support for variable names containing "$". fix #102

0.4.3 / 2013-03-18 
==================

  * fix dox(1) --version. Closes #91
  * fix ctx.string on properties of a prototype
  * add support tab-indented comments

0.4.2 / 2013-01-18 
==================

  * Prevent error when using --api & comments have no example code.

0.4.1 / 2012-11-11 
==================

  * change # to . in --api

0.4.0 / 2012-11-09 
==================

  * add TOC to --api. Closes #72
  * add gfm code blocks. Closes #71
  * remove implicit titles. Closes #70

0.3.3 / 2012-10-16 
==================

  * fix --api .receiver

0.3.2 / 2012-10-01 
==================

  * add dox --api

0.3.1 / 2012-04-25 
==================

  * Fixed annoying title bug

0.3.0 / 2012-03-27 
==================

  * Added __@memberOf__ [olivernn]
  * Added __@arguments__ [olivernn]
  * Added __@borrows__ [olivernn]

0.2.0 / 2012-02-23 
==================

  * Added `-r, --raw` support. Closes #48

0.1.3 / 2011-12-08 
==================

  * Added: allow arbitrary tags [logicalparadox]
  * Fixed function whitespace [TooTallNate]

0.1.2 / 2011-10-22 
==================

  * remove html escaping for now

0.1.1 / 2011-10-10 
==================

  * Fixed: colons in comment lines not intended as headers [Evan Owen]

0.0.5 / 2011-03-02 
==================

  * Adding "main" to package descriptor since "directories" are no longer supported.

0.0.4 / 2011-01-20 
==================

  * Added `--intro` support for including an intro file written in markdown [Alex Young]

0.0.3 / 2010-07-15
==================

  * Linked h2s

0.0.2 / 2010-07-15
==================

  * Collapsing files, click to open. Closes #19
  * Fixed ribbon position instead of absolute
  * Removed menu
  * Removed node-discount dependency, using markdown-js

