/* eslint no-cond-assign:0 */
'use strict'; // Import

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance"); }

function _iterableToArrayLimit(arr, i) { if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) { return; } var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var typeChecker = require('typechecker'); // Eachr


module.exports = function eachr(subject, callback) {
  // Handle
  if (typeChecker.isArray(subject)) {
    for (var key = 0; key < subject.length; ++key) {
      var value = subject[key];

      if (callback.call(subject, value, key, subject) === false) {
        break;
      }
    }
  } else if (typeChecker.isPlainObject(subject)) {
    for (var _key in subject) {
      if (subject.hasOwnProperty(_key)) {
        var _value = subject[_key];

        if (callback.call(subject, _value, _key, subject) === false) {
          break;
        }
      }
    }
  } else if (typeChecker.isMap(subject)) {
    var entries = subject.entries();
    var entry;

    while (entry = entries.next().value) {
      var _entry = entry,
          _entry2 = _slicedToArray(_entry, 2),
          _key2 = _entry2[0],
          _value2 = _entry2[1]; // destructuring


      if (callback.call(subject, _value2, _key2, subject) === false) {
        break;
      }
    }
  } else {
    // Perhaps falling back to a `for of` loop here would be sensible
    throw new Error('eachr does not know how to iterate what was passed to it');
  } // Return


  return subject;
};