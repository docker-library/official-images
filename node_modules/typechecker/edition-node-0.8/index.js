"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getObjectType = getObjectType;
exports.isObject = isObject;
exports.isPlainObject = isPlainObject;
exports.isEmpty = isEmpty;
exports.isEmptyObject = isEmptyObject;
exports.isNativeClass = isNativeClass;
exports.isConventionalClass = isConventionalClass;
exports.isClass = isClass;
exports.isError = isError;
exports.isDate = isDate;
exports.isArguments = isArguments;
exports.isSyncFunction = isSyncFunction;
exports.isAsyncFunction = isAsyncFunction;
exports.isFunction = isFunction;
exports.isRegExp = isRegExp;
exports.isArray = isArray;
exports.isNumber = isNumber;
exports.isString = isString;
exports.isBoolean = isBoolean;
exports.isNull = isNull;
exports.isUndefined = isUndefined;
exports.isMap = isMap;
exports.isWeakMap = isWeakMap;
exports.getType = getType;
exports.typeMap = void 0;

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

/* eslint quote-props:0 */
// Prepare
var isClassRegex = /^class\s|^function\s+[A-Z]/;
var isConventionalClassRegex = /^function\s+[A-Z]/;
var isNativeClassRegex = /^class\s/;
/** Determines if the passed value is of a specific type */

// -----------------------------------
// Values

/** Get the object type string */
function getObjectType(value) {
  return Object.prototype.toString.call(value);
}
/** Checks to see if a value is an object */


function isObject(value) {
  // null is object, hence the extra check
  return value !== null && _typeof(value) === 'object';
}
/** Checks to see if a value is an object and only an object */


function isPlainObject(value) {
  /* eslint no-proto:0 */
  return isObject(value) && value.__proto__ === Object.prototype;
}
/** Checks to see if a value is empty */


function isEmpty(value) {
  return value == null;
}
/**
 * Is empty object */


function isEmptyObject(value) {
  // We could use Object.keys, but this is more effecient
  for (var key in value) {
    if (value.hasOwnProperty(key)) {
      return false;
    }
  }

  return true;
}
/**
 * Is ES6+ class */


function isNativeClass(value) {
  // NOTE TO DEVELOPER: If any of this changes, isClass must also be updated
  return typeof value === 'function' && isNativeClassRegex.test(value.toString());
}
/**
 * Is Conventional Class
 export * Looks for function with capital first letter MyClass
 * First letter is the 9th character
 * If changed, isClass must also be updated */


function isConventionalClass(value) {
  return typeof value === 'function' && isConventionalClassRegex.test(value.toString());
}

// There use to be code here that checked for CoffeeScript's "function _Class" at index 0 (which was sound)
// But it would also check for Babel's __classCallCheck anywhere in the function, which wasn't sound
// as somewhere in the function, another class could be defined, which would provide a false positive
// So instead, proxied classes are ignored, as we can't guarantee their accuracy, would also be an ever growing set
// -----------------------------------
// Types

/**
 * Is Class */
function isClass(value) {
  return typeof value === 'function' && isClassRegex.test(value.toString());
}
/** Checks to see if a value is an error */


function isError(value) {
  return value instanceof Error;
}
/** Checks to see if a value is a date */


function isDate(value) {
  return getObjectType(value) === '[object Date]';
}
/** Checks to see if a value is an arguments object */


function isArguments(value) {
  return getObjectType(value) === '[object Arguments]';
}
/**
 export * Checks to see if a value is a function but not an asynchronous function */


function isSyncFunction(value) {
  return getObjectType(value) === '[object Function]';
}
/** Checks to see if a value is an asynchronous function */


function isAsyncFunction(value) {
  return getObjectType(value) === '[object AsyncFunction]';
}
/** Checks to see if a value is a function */


function isFunction(value) {
  return isSyncFunction(value) || isAsyncFunction(value);
}
/** Checks to see if a value is an regex */


function isRegExp(value) {
  return getObjectType(value) === '[object RegExp]';
}
/** Checks to see if a value is an array */


function isArray(value) {
  return typeof Array.isArray === 'function' && Array.isArray(value) || getObjectType(value) === '[object Array]';
}
/** Checks to see if a valule is a number */


function isNumber(value) {
  return typeof value === 'number' || getObjectType(value) === '[object Number]';
}
/** Checks to see if a value is a string */


function isString(value) {
  return typeof value === 'string' || getObjectType(value) === '[object String]';
}
/** Checks to see if a valule is a boolean */


function isBoolean(value) {
  return value === true || value === false || getObjectType(value) === '[object Boolean]';
}
/** Checks to see if a value is null */


function isNull(value) {
  return value === null;
}
/** Checks to see if a value is undefined */


function isUndefined(value) {
  return typeof value === 'undefined';
}
/** Checks to see if a value is a Map */


function isMap(value) {
  return getObjectType(value) === '[object Map]';
}
/** Checks to see if a value is a WeakMap */


function isWeakMap(value) {
  return getObjectType(value) === '[object WeakMap]';
} // -----------------------------------
// General

/**
 * The default {@link TypeMap} for {@link getType}.
 export * AsyncFunction and SyncFunction are missing, as they are more specific types that people can detect afterwards.
 * @readonly
 */


var typeMap = Object.freeze({
  array: isArray,
  "boolean": isBoolean,
  date: isDate,
  error: isError,
  "class": isClass,
  "function": isFunction,
  "null": isNull,
  number: isNumber,
  regexp: isRegExp,
  string: isString,
  undefined: isUndefined,
  map: isMap,
  weakmap: isWeakMap,
  object: isObject
});
/**
 * Cycle through the passed {@link TypeMap} testing the value, returning the first type that passes, otherwise `null`.
 * @param value the value to test
 * @param customTypeMap defaults to {@link typeMap}
 */

exports.typeMap = typeMap;

function getType(value) {
  var customTypeMap = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : typeMap;

  // Cycle through our type map
  for (var key in customTypeMap) {
    if (customTypeMap.hasOwnProperty(key)) {
      if (customTypeMap[key](value)) {
        return key;
      }
    }
  } // No type was successful


  return null;
}