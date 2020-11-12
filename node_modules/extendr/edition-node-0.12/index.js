'use strict'; // Import

var typeChecker = require('typechecker');
/**
 * The options that are available to customise the behaviour of {@link custom}.
 * @typedef {object} Options
 * @property {boolean} [defaults=false] Only extend with a source value, if the target value is null or undefined.
 * @property {boolean} [traverse=false] If false, a shallow extend will be performed, if a true a deep/nested extend will be performed.
 */

/**
 * Extend target with the objects, with customisations.
 *
 * Target and sources can only be plain objects, any other type will throw, this is intentional to guarantee consistency of references.
 * Source values that are injected, will be dereferenced if they are plain objects or arrays.
 *
 * Plain Objects and Arrays will be dereferenced. All other types will keep their reference.
 *
 * @private
 * @param {Options} options
 * @param {object} target
 * @param  {...object} sources
 * @returns {object} target
 * @throws {Error} Throws in the case that the target or a source was not a plain object.
 */


function custom(options, target) {
  var _options$defaults = options.defaults,
      defaults = _options$defaults === void 0 ? false : _options$defaults,
      _options$traverse = options.traverse,
      traverse = _options$traverse === void 0 ? false : _options$traverse;

  if (!typeChecker.isPlainObject(target)) {
    throw new Error('extendr only supports extending plain objects, target was not a plain object');
  }

  for (var objIndex = 0; objIndex < (arguments.length <= 2 ? 0 : arguments.length - 2); ++objIndex) {
    var obj = objIndex + 2 < 2 || arguments.length <= objIndex + 2 ? undefined : arguments[objIndex + 2];

    if (!typeChecker.isPlainObject(obj)) {
      throw new Error('extendr only supports extending plain objects, an input was not a plain object');
    }

    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        // if not defaults only, always overwrite
        // if defaults only, overwrite if current value is empty
        var defaultSkip = defaults && target[key] != null; // get the new value

        var newValue = obj[key]; // ensure everything is new

        if (typeChecker.isPlainObject(newValue)) {
          if (traverse && typeChecker.isPlainObject(target[key])) {
            // replace current value with
            // dereferenced merged new object
            target[key] = custom({
              traverse: traverse,
              defaults: defaults
            }, {}, target[key], newValue);
          } else if (!defaultSkip) {
            // replace current value with
            // dereferenced new object
            target[key] = custom({
              defaults: defaults
            }, {}, newValue);
          }
        } else if (!defaultSkip) {
          if (typeChecker.isArray(newValue)) {
            // replace current value with
            // dereferenced new array
            target[key] = newValue.slice();
          } else {
            // replace current value with
            // possibly referenced: function, class, etc
            // possibly unreferenced: string
            // new value
            target[key] = newValue;
          }
        }
      }
    }
  }

  return target;
}
/**
 * Shallow extend the properties from the sources into the target.
 * Performs {@link custom} with default options.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */


function extend(target) {
  for (var _len = arguments.length, sources = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
    sources[_key - 1] = arguments[_key];
  }

  return custom.apply(void 0, [{}, target].concat(sources));
}
/**
 * Deep extend the properties from the sources into the target.
 * Performs {@link custom} with +traverse.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */


function deep(target) {
  for (var _len2 = arguments.length, sources = new Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
    sources[_key2 - 1] = arguments[_key2];
  }

  return custom.apply(void 0, [{
    traverse: true
  }, target].concat(sources));
}
/**
 * Shallow extend the properties from the sources into the target, where the target's value is `undefined` or `null`.
 * Performs {@link custom} with +defaults.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */


function defaults(target) {
  for (var _len3 = arguments.length, sources = new Array(_len3 > 1 ? _len3 - 1 : 0), _key3 = 1; _key3 < _len3; _key3++) {
    sources[_key3 - 1] = arguments[_key3];
  }

  return custom.apply(void 0, [{
    defaults: true
  }, target].concat(sources));
}
/**
 * Deep extend the properties from the sources into the target, where the target's value is `undefined` or `null`.
 * Performs {@link custom} with +traverse +defaults.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */


function deepDefaults(target) {
  for (var _len4 = arguments.length, sources = new Array(_len4 > 1 ? _len4 - 1 : 0), _key4 = 1; _key4 < _len4; _key4++) {
    sources[_key4 - 1] = arguments[_key4];
  }

  return custom.apply(void 0, [{
    traverse: true,
    defaults: true
  }, target].concat(sources));
}
/**
 * Deep extends the properties from the sources into a new object.
 * Performs {@link custom} with +traverse.
 * @param {...object} sources
 * @returns {object} target
 */


function clone() {
  for (var _len5 = arguments.length, sources = new Array(_len5), _key5 = 0; _key5 < _len5; _key5++) {
    sources[_key5] = arguments[_key5];
  }

  return custom.apply(void 0, [{
    traverse: true
  }, {}].concat(sources));
}
/**
 * Clones the object by stringifying it, then parsing the result, to ensure all references are destroyed.
 * Only serialisable values are kept, this means:
 * - Objects that are neither a Plain Object nor an Array will be lost.
 * - Class Instances, Functions and Regular Expressions will be discarded.
 * @param {object} source
 * @returns {object} dereferenced source
 */


function dereferenceJSON(source) {
  return JSON.parse(JSON.stringify(source));
}
/**
 * Clones the object by traversing through it and setting up new instances of anything that can be referenced.
 * Dereferences most things, including Regular Expressions.
 * Will not dereference functions and classes, they will throw.
 * @param {object} source
 * @returns {object} dereferenced source
 * @throws {Error} Throws in the case it encounters something it cannot dereference.
 */


function dereference(source) {
  if (typeChecker.isString(source)) {
    return source.toString();
  }

  if (typeChecker.isUndefined(source)) {
    return;
  }

  if (typeChecker.isNull(source)) {
    return null;
  }

  if (typeChecker.isNumber(source) || typeChecker.isBoolean(source)) {
    return dereferenceJSON(source);
  }

  if (typeChecker.isPlainObject(source)) {
    var result = {};

    for (var key in source) {
      if (source.hasOwnProperty(key)) {
        var value = source[key];
        result[key] = dereference(value);
      }
    }

    return result;
  }

  if (typeChecker.isArray(source)) {
    return source.map(function (item) {
      return dereference(item);
    });
  }

  if (typeChecker.isDate(source)) {
    return new Date(source.toISOString());
  }

  if (typeChecker.isRegExp(source)) {
    if (source.flags == null) {
      throw new Error('extendr cannot derefence RegExps on this older version of node');
    } else {
      return new RegExp(source.source, source.flags);
    }
  }

  throw new Error('extendr was passed an object type that it does not know how to derefence');
} // Export


module.exports = {
  custom: custom,
  extend: extend,
  deep: deep,
  defaults: defaults,
  deepDefaults: deepDefaults,
  clone: clone,
  dereference: dereference,
  dereferenceJSON: dereferenceJSON
};