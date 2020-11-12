'use strict';

var bind = Function.prototype.bind;

function define(bounded, unbounded) {
  if (bounded.unbounded !== unbounded) {
    Object.defineProperty(bounded, 'unbounded', {
      value: unbounded.unbounded || unbounded,
      enumerable: false,
      configurable: false,
      writable: false
    });
  }

  return bounded;
}

function binder() {
  for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
    args[_key] = arguments[_key];
  }

  var bounded = bind.apply(this, args);
  define(bounded, this);
  return bounded;
}

function patch() {
  if (Function.prototype.bind !== binder) {
    /* eslint no-extend-native:0 */
    Function.prototype.bind = binder;
  }

  return module.exports;
}

module.exports = {
  bind: bind,
  binder: binder,
  patch: patch,
  define: define
};