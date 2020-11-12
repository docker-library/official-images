/* eslint no-extra-parens:0 */
'use strict'; // Domains are crippled in the browser and on node 0.8, so don't use domains in those environments

var domain = process.browser || process.versions.node.substr(0, 3) === '0.8' ? null : require('domain'); // Cross-platform (node 0.10+, node 0.8+, browser) compatible setImmediate

var queue = (global || window).setImmediate || process && process.nextTick || function (fn) {
  setTimeout(fn, 0);
}; // Convert an error to a string


function errorToString(error) {
  if (!error) {
    return null;
  } else if (error.stack) {
    return error.stack.toString();
  } else if (error.message) {
    return error.message.toString();
  } else {
    return error.toString();
  }
} // Ensure that the passed array is actually an array


function ensureArray(arr) {
  if (!Array.isArray(arr)) arr = [arr];
  return arr;
} // Exports


module.exports = {
  domain: domain,
  queue: queue,
  errorToString: errorToString,
  ensureArray: ensureArray
};