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
export function getObjectType(value) {
  return Object.prototype.toString.call(value);
}
/** Checks to see if a value is an object */

export function isObject(value) {
  // null is object, hence the extra check
  return value !== null && _typeof(value) === 'object';
}
/** Checks to see if a value is an object and only an object */

export function isPlainObject(value) {
  /* eslint no-proto:0 */
  return isObject(value) && value.__proto__ === Object.prototype;
}
/** Checks to see if a value is empty */

export function isEmpty(value) {
  return value == null;
}
/**
 * Is empty object */

export function isEmptyObject(value) {
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

export function isNativeClass(value) {
  // NOTE TO DEVELOPER: If any of this changes, isClass must also be updated
  return typeof value === 'function' && isNativeClassRegex.test(value.toString());
}
/**
 * Is Conventional Class
 export * Looks for function with capital first letter MyClass
 * First letter is the 9th character
 * If changed, isClass must also be updated */

export function isConventionalClass(value) {
  return typeof value === 'function' && isConventionalClassRegex.test(value.toString());
}
export // There use to be code here that checked for CoffeeScript's "function _Class" at index 0 (which was sound)
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

export function isError(value) {
  return value instanceof Error;
}
/** Checks to see if a value is a date */

export function isDate(value) {
  return getObjectType(value) === '[object Date]';
}
/** Checks to see if a value is an arguments object */

export function isArguments(value) {
  return getObjectType(value) === '[object Arguments]';
}
/**
 export * Checks to see if a value is a function but not an asynchronous function */

export function isSyncFunction(value) {
  return getObjectType(value) === '[object Function]';
}
/** Checks to see if a value is an asynchronous function */

export function isAsyncFunction(value) {
  return getObjectType(value) === '[object AsyncFunction]';
}
/** Checks to see if a value is a function */

export function isFunction(value) {
  return isSyncFunction(value) || isAsyncFunction(value);
}
/** Checks to see if a value is an regex */

export function isRegExp(value) {
  return getObjectType(value) === '[object RegExp]';
}
/** Checks to see if a value is an array */

export function isArray(value) {
  return typeof Array.isArray === 'function' && Array.isArray(value) || getObjectType(value) === '[object Array]';
}
/** Checks to see if a valule is a number */

export function isNumber(value) {
  return typeof value === 'number' || getObjectType(value) === '[object Number]';
}
/** Checks to see if a value is a string */

export function isString(value) {
  return typeof value === 'string' || getObjectType(value) === '[object String]';
}
/** Checks to see if a valule is a boolean */

export function isBoolean(value) {
  return value === true || value === false || getObjectType(value) === '[object Boolean]';
}
/** Checks to see if a value is null */

export function isNull(value) {
  return value === null;
}
/** Checks to see if a value is undefined */

export function isUndefined(value) {
  return typeof value === 'undefined';
}
/** Checks to see if a value is a Map */

export function isMap(value) {
  return getObjectType(value) === '[object Map]';
}
/** Checks to see if a value is a WeakMap */

export function isWeakMap(value) {
  return getObjectType(value) === '[object WeakMap]';
} // -----------------------------------
// General

/**
 * The default {@link TypeMap} for {@link getType}.
 export * AsyncFunction and SyncFunction are missing, as they are more specific types that people can detect afterwards.
 * @readonly
 */

export var typeMap = Object.freeze({
  array: isArray,
  boolean: isBoolean,
  date: isDate,
  error: isError,
  class: isClass,
  function: isFunction,
  null: isNull,
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

export function getType(value) {
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