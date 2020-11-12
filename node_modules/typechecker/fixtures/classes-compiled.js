'use strict';

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var A = function A() {
  _classCallCheck(this, A);
};

var a = function a() {
  _classCallCheck(this, a);
};

var b = function b() {
  _classCallCheck(this, b);
};

var C =
/*#__PURE__*/
function (_A) {
  _inherits(C, _A);

  function C() {
    _classCallCheck(this, C);

    return _possibleConstructorReturn(this, _getPrototypeOf(C).apply(this, arguments));
  }

  return C;
}(A);

var D =
/*#__PURE__*/
function () {
  function D() {
    _classCallCheck(this, D);
  }

  _createClass(D, [{
    key: "z",
    value: function z() {
      return this;
    }
  }]);

  return D;
}();

var E =
/*#__PURE__*/
function (_D) {
  _inherits(E, _D);

  function E() {
    _classCallCheck(this, E);

    return _possibleConstructorReturn(this, _getPrototypeOf(E).apply(this, arguments));
  }

  return E;
}(D);

var F =
/*#__PURE__*/
function (_E) {
  _inherits(F, _E);

  function F() {
    var _this;

    _classCallCheck(this, F);

    _this = _possibleConstructorReturn(this, _getPrototypeOf(F).call(this));
    _this.greeting = 'hello';
    return _this;
  }

  return F;
}(E);

module.exports = {
  A: A,
  a: a,
  b: b,
  C: C,
  D: D,
  E: E,
  F: F
};