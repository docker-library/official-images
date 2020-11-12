// # getColourScheme.js
//
// This is a helper to grab the colours out of a given highlight.js theme.
// It's a bit messy, but oh well.


// Require all node modules
var path = require('path');
var css = require('css');
var fs = require('fs');

// Figure out where the colour schemes are stored
var hlpath = require.resolve('highlight.js');
var cspath = path.resolve(path.dirname(hlpath), '..', 'styles');


/**
 * ## flattenRules
 *
 * Flattens out all the rules in a CSS file so we can easily grab
 * rules for a particular selector.
 *
 * @param {Array} rules Array of rules parsed by **css**
 * @return {Object} Selctor -> property/value list
 */
function flattenRules(rules) {
  var out = {};

  rules.forEach(function(rule) {
    // Ignore anything that doesn't look like a CSS rule
    if (rule.type !== 'rule') return;
    rule.selectors.forEach(function(sel) {
      if (!out[sel]) out[sel] = {};

      rule.declarations.forEach(function(decl) {
        out[sel][decl.property] = decl.value;
      });
    });
  });

  return out;
}

module.exports = function(cs) {
  // Load and parse the colour scheme file
  var file = path.join(cspath, cs + '.css');
  var ast = css.parse(fs.readFileSync(file).toString());

  // Flatten out all the rules so we can grab individual properties by selector
  var rules = flattenRules(ast.stylesheet.rules);

  var base = rules['.hljs'];

  var fg = base.color || 'black';
  var bg = base.background || '#fff';

  var comment = rules['.hljs-comment'] || {};
  var commentColour = comment.color || '#888';

  var number = rules['.hljs-number'] || rules['.javascript .hljs-number'] || {};
  var numberCol = number.color || '#261a3b';

  return { fg: fg, bg: bg, comment: commentColour, link: numberCol };
};
