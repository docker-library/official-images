# toc [![Build Status](https://secure.travis-ci.org/cowboy/node-toc.png?branch=master)](http://travis-ci.org/cowboy/node-toc)

Linkify HTML headers and generate a TOC.

## Getting Started
Install the module with: `npm install toc`

```js
var toc = require('toc');
```

## Documentation

### toc.untag
Strip HTML tags from a string.

```js
var stripped = toc.untag(html);
```

### toc.anchor
Convert a string of text into something URL-friendly and not too fugly.

```js
var anchor = toc.anchor(arbitraryText);
```


### toc.unique
Get a unique name and store the returned name in names for future unique-name-gettingness.

```js
var names = {};
var guaranteedUniqueAnchor1 = toc.unique(names, toc.anchor(arbitraryText));
var guaranteedUniqueAnchor2 = toc.unique(names, toc.anchor(arbitraryText));
```


### toc.process
Anchorize all headers and inline a generated TOC, returning processed HTML.

```js
var htmlWithAnchorsAndTOC = toc.process(html [, options]);
```

#### options

* **placeholder** - `RegExp` - Used to match TOC placeholder. Defaults to `/<!--\s*toc\s*-->/gi`.
* _Because this method calls the `toc.anchorize` and `toc.toc` methods internally, their options may be specified as well._


### toc.anchorize
Parse HTML, returning an array of header objects and anchorized HTML.

```js
var obj = toc.anchorize(html [, options]);
```

#### options

* **headers** - `RegExp` - Used to match HTML headers. Defaults to `/<h(\d)(\s*[^>]*)>([\s\S]+?)<\/h\1>/gi`.
* **tocMin** - `Number` - Min header level to add to TOC. Defaults to `2`.
* **tocMax** - `Number` - Max header level to add to TOC. Defaults to `6`.
* **anchorMin** - `Number` - Min header level to anchorize. Defaults to `2`.
* **anchorMax** - `Number` - Max header level to anchorize. Defaults to `6`.
* **header** - `String` | `Function` - Lodash template string or function used to anchorize a header.


### toc.toc
Generate TOC HTML from an array of header objects.

```js
var obj = toc.toc(headers [, options]);
```

#### options

* **openUL** - `String` | `Function` - Lodash template string or function used to generate the TOC.
* **closeUL** - `String` | `Function` - Lodash template string or function used to generate the TOC.
* **openLI** - `String` | `Function` - Lodash template string or function used to generate the TOC.
* **closeLI** - `String` | `Function` - Lodash template string or function used to generate the TOC.
* **TOC** - `String` | `Function` - Lodash template string or function used to wrap the generated TOC.


## Examples

The default HTML is pretty awesome, but you can customize the hell out of the generated HTML, eg.

```js
var processedHTML = toc.process(unprocessedHTML, {
  header: '<h<%= level %><%= attrs %> id="<%= anchor %>"><%= header %></h<%= level %>>',
  TOC: '<div class="toc"><%= toc %></div>',
  openUL: '<ul data-depth="<%= depth %>">',
  closeUL: '</ul>',
  openLI: '<li data-level="H<%= level %>"><a href="#<%= anchor %>"><%= text %></a>',
  closeLI: '</li>',
});
```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
2014-02-28 - v0.4.0 - Updated a bunch of dependencies. Functionality shouldn't change, and all test pass, but YMMV.  
2013-03-08 - v0.3.0 - Separated `.process` method internals into `.anchorize` and `.toc` methods. Renamed `toc` template option to `TOC`.  
2013-03-07 - v0.2.0 - Second official release. Minor changes.  
2013-03-07 - v0.1.0 - First official release.
