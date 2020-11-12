/*
 * toc
 * https://github.com/cowboy/node-toc
 *
 * Copyright (c) 2013 "Cowboy" Ben Alman
 * Licensed under the MIT license.
 */

'use strict';

var _ = require('lodash');

var toc = exports;

// Default options.
toc.defaults = {
  // DEFAULTS FOR toc.process()
  //
  // RegExp to replace with generated TOC.
  placeholder: /<!--\s*toc\s*-->/gi,

  // DEFAULTS FOR toc.anchorize()
  //
  // Match H? headers and all their contents.
  headers: /<h(\d)(\s*[^>]*)>([\s\S]+?)<\/h\1>/gi,
  // Min and max headers to add to TOC.
  tocMin: 2,
  tocMax: 6,
  // Min and max headers to anchorize.
  anchorMin: 2,
  anchorMax: 6,
  // Anchorized header template.
  header: '<h<%= level %><%= attrs %>><a href="#<%= anchor %>" name="<%= anchor %>"><%= header %></a></h<%= level %>>',

  // DEFAULTS FOR toc.toc()
  //
  // TOC part templates.
  openUL: '<ul>',
  closeUL: '</ul>',
  openLI: '<li><a href="#<%= anchor %>"><%= text %></a>',
  // openLI: '<li><a href="#<%= anchor %>"><%= text %></a> (<%= depth %> / H<%= level %>)',
  closeLI: '</li>',
  // Main TOC template.
  TOC: '<div class="toc"><%= toc %></div>',
};

// Strip HTML tags from a string.
toc.untag = function(s) {
  return s.replace(/<[^>]*>/g, '');
};

// Convert a string of text into something URL-friendly and not too fugly.
toc.anchor = function(s) {
  var slug = require('slug');
  var entities = require('entities');

  s = toc.untag(s);
  s = s.toLowerCase();
  s = entities.decode(s);
  s = s.replace(/['"!]|[\.]+$/g, '');
  s = slug(s);
  s = s.replace(/[:\(\)]+/gi, '-');
  s = s.replace(/[\s\-]*([\.])[\s\-]*/g, '$1');
  s = s.replace(/-+/g, '-');
  s = s.replace(/^-+|-+$/g, '');
  return s;
};

// Get a unique name and store the returned name in names for future
// unique-name-gettingness.
toc.unique = function(names, name) {
  var result = name;
  var count = 0;
  while (names[result]) {
    result = name + (--count);
  }
  names[result] = true;
  return result;
};

// Compile specified lodash string template properties into functions.
function normalize(options, templates) {
  // Options override defaults and toc methods.
  var result = _.defaults({}, options, toc, toc.defaults);
  // Remove "core" methods from result object.
  ['defaults', 'process', 'anchorize', 'toc'].forEach(function(prop) {
    delete result[prop];
  });
  // Compile Lodash string templates into functions.
  (templates || []).forEach(function(tmpl) {
    if (typeof result[tmpl] === 'string') {
      result[tmpl] = _.template(result[tmpl]);
    }
  });
  return result;
}

// Anchorize all headers and inline a generated TOC, returning processed HTML.
toc.process = function(src, options) {
  // Get anchorized HTML and headers array.
  var anchorized = toc.anchorize(src, options);
  // Generate TOC from headers array.
  var tocHtml = toc.toc(anchorized.headers, options);
  // Insert the generated TOC into the anchorized HTML.
  return anchorized.html.replace(normalize(options).placeholder, tocHtml);
};

// Parse HTML, returning an array of header objects and anchorized HTML.
toc.anchorize = function(src, options) {
  // Normalize options and compile template(s).
  options = normalize(options, ['header']);
  // Process HTML, "anchorizing" headers as-specified.
  var headers = [];
  var names = {};
  var html = src.replace(options.headers, function(all, level, attrs, header) {
    level = Number(level);
    var tocLevel = level >= options.tocMin && level <= options.tocMax;
    var anchorLevel = level >= options.anchorMin && level <= options.anchorMax;
    var data;
    if (tocLevel || anchorLevel) {
      // This data is passed into the specified "header" template function.
      data = {
        // The header level number in <H?>...</H?>
        level: level,
        // Any attributes in the open H? tag.
        attrs: attrs,
        // Header HTML contents.
        header: header,
        // Un-tagged header HTML contents.
        text: options.untag(header),
        // Unique anchor name for this header.
        anchor: options.unique(names, options.anchor(header)),
        // All HTML (including tags) matched by the "headers" RegExp.
        all: all,
      };
    }
    if (tocLevel) {
      headers.push(data);
    }
    return anchorLevel ? options.header(data) : all;
  });

  return {
    src: src,
    html: html,
    headers: headers,
  };
};

// Generate TOC HTML from an array of header objects.
toc.toc = function(headers, options) {
  // Normalize options and compile template(s).
  options = normalize(options, ['TOC', 'openUL', 'closeUL', 'openLI', 'closeLI']);

  // Build TOC.
  var cursor = 0;
  var levels = [];
  var tocs = [''];
  headers.forEach(function(header) {
    while (header.level < levels[0]) {
      levels.shift();
      cursor++;
    }
    if (levels.length === 0 || header.level > levels[0]) {
      levels.unshift(header.level);
      header.depth = levels.length;
      tocs[cursor] += options.openUL(header);
      tocs.push(options.closeLI(header) + options.closeUL(header));
    } else {
      header.depth = levels.length;
      tocs[cursor] += options.closeLI(header);
    }
    tocs[cursor] += options.openLI(header);
  });

  return options.TOC({toc: tocs.join('')});
};
