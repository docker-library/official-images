"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isIgnoredPath = isIgnoredPath;

var _path = _interopRequireDefault(require("path"));

var _ignorepatterns = _interopRequireDefault(require("ignorepatterns"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Import

/**
 * Is Ignored Path
 * Check to see if a path, either a full path or basename, should be ignored
 * @param path A full path or basename of a file or directory
 * @param opts Configurations options
 * @returns Whether or not the path should be ignored
 */
function isIgnoredPath(path) {
  var opts = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

  // Prepare
  var basename = _path.default.basename(path); // Test Paths


  if (opts.ignorePaths) {
    for (var i = 0; i < opts.ignorePaths.length; ++i) {
      var ignorePath = opts.ignorePaths[i];

      if (path.indexOf(ignorePath) === 0) {
        return true;
      }
    }
  } // Test Hidden Files


  if (opts.ignoreHiddenFiles && basename[0] === '.') {
    return true;
  } // Test Common Patterns


  if (opts.ignoreCommonPatterns == null || opts.ignoreCommonPatterns === true) {
    return _ignorepatterns.default.test(path) || path !== basename && _ignorepatterns.default.test(basename);
  } else if (opts.ignoreCommonPatterns) {
    var ignoreCommonPatterns
    /* :RegExp */
    = opts.ignoreCommonPatterns;
    return ignoreCommonPatterns.test(path) || path !== basename && ignoreCommonPatterns.test(basename);
  } // Test Custom Patterns


  if (opts.ignoreCustomPatterns) {
    var ignoreCustomPatterns
    /* :RegExp */
    = opts.ignoreCustomPatterns;
    return ignoreCustomPatterns.test(path) || path !== basename && ignoreCustomPatterns.test(basename);
  } // Return


  return false;
}