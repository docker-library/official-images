'use strict';
/**
Base class containing common functionality for {@link Task} and {@link TaskGroup}.

Adds support for the done event while
ensuring that errors are always handled correctly.
It does this by listening to the `error` and `completed` events,
and when the emit, we check if there is a `done` listener:

- if there is, then emit the done event with the original event arguments
- if there isn't, then output the error to stderr and throw it.

Sets the following configuration:

- `nameSeparator` defaults to `' ➞  '`, used to stringify the result of `.names`

@class BaseInterface
@extends EventEmitter
@constructor
@access private
*/

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function _construct(Parent, args, Class) { if (isNativeReflectConstruct()) { _construct = Reflect.construct; } else { _construct = function _construct(Parent, args, Class) { var a = [null]; a.push.apply(a, args); var Constructor = Function.bind.apply(Parent, a); var instance = new Constructor(); if (Class) _setPrototypeOf(instance, Class.prototype); return instance; }; } return _construct.apply(null, arguments); }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance"); }

function _iterableToArray(iter) { if (Symbol.iterator in Object(iter) || Object.prototype.toString.call(iter) === "[object Arguments]") return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = new Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

var BaseInterface =
/*#__PURE__*/
function (_require$EventEmitter) {
  _inherits(BaseInterface, _require$EventEmitter);

  function BaseInterface() {
    var _this;

    _classCallCheck(this, BaseInterface);

    _this = _possibleConstructorReturn(this, _getPrototypeOf(BaseInterface).call(this)); // Allow extensions of this class to prepare the class instance before anything else fires

    if (_this.prepare) {
      _this.prepare();
    } // Set state and config


    if (_this.state == null) _this.state = {};
    if (_this.config == null) _this.config = {};
    if (_this.config.nameSeparator == null) _this.config.nameSeparator = ' ➞  '; // Generate our listener method that we will beind to different events
    // to add support for the `done` event and better error/event handling

    function listener(event) {
      for (var _len = arguments.length, args = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
        args[_key - 1] = arguments[_key];
      }

      // Prepare
      var error = args[0]; // has done listener, forward to that

      if (this.listeners('done').length !== 0) {
        this.emit.apply(this, ['done'].concat(args));
      } // has error, but no done listener and no event listener, throw error
      else if (error && this.listeners(event).length === 1) {
          if (event === 'error') {
            throw error;
          } else {
            this.emit('error', error);
          }
        }
    } // Listen to the different events without listener


    _this.on('error', listener.bind(_assertThisInitialized(_this), 'error'));

    _this.on('completed', listener.bind(_assertThisInitialized(_this), 'completed')); // this.on('halted', listener.bind(this, 'halted'))
    // ^ @TODO not yet implemented, would be an alternative to pausing


    return _this;
  }
  /**
  Creates and returns new instance of the current class.
  @param {...*} args - The arguments to be forwarded along to the constructor.
  @return {BaseInterface} The new instance.
  	@static
  @access public
  */


  _createClass(BaseInterface, [{
    key: "whenDone",

    /**
    Attaches the listener to the `done` event to be emitted each time.
    @param {Function} listener - Attaches to the `done` event.
    @chainable
    @returns {BaseInterface} this
    @access public
    */
    value: function whenDone(listener) {
      // Attach the listener
      this.on('done', listener.bind(this)); // Chain

      return this;
    }
    /**
    Attaches the listener to the `done` event to be emitted only once, then removed to not fire again.
    @param {Function} listener - Attaches to the `done` event.
    @chainable
    @returns {BaseInterface} this
    @access public
    */

  }, {
    key: "onceDone",
    value: function onceDone(listener) {
      // Attach the listener
      this.once('done', listener.bind(this)); // Chain

      return this;
    }
    /**
    Alias for {@link BaseInterface#onceDone}
    @param {Function} listener - Attaches to the `done` event.
    @chainable
    @returns {BaseInterface} this
    @access public
    */

  }, {
    key: "done",
    value: function done(listener) {
      return this.onceDone(listener);
    }
    /**
    Gets our name prepended by all of our parents names
    @type {Array}
    @access public
    */

  }, {
    key: "getNames",
    // ---------------------------------
    // Backwards compatability helpers
    value: function getNames(opts) {
      return opts && opts.separator ? this.names.join(opts.separator) : this.names;
    }
  }, {
    key: "getConfig",
    value: function getConfig() {
      return this.config;
    }
  }, {
    key: "getTotalItems",
    value: function getTotalItems() {
      return this.totalItems;
    }
  }, {
    key: "getItemTotals",
    value: function getItemTotals() {
      return this.itemTotals;
    }
  }, {
    key: "isCompleted",
    value: function isCompleted() {
      return this.completed;
    }
  }, {
    key: "hasStarted",
    value: function hasStarted() {
      return this.started;
    }
  }, {
    key: "addGroup",
    value: function addGroup() {
      return this.addTaskGroup.apply(this, arguments);
    }
  }, {
    key: "clear",
    value: function clear() {
      this.clearRemaining.apply(this, arguments);
      return this;
    }
  }, {
    key: "names",
    get: function get() {
      // Fetch
      var names = [],
          _this$config = this.config,
          name = _this$config.name,
          parent = _this$config.parent,
          nameSeparator = _this$config.nameSeparator;
      if (parent) names.push.apply(names, _toConsumableArray(parent.names));
      if (name !== false) names.push(this.name);

      names.toString = function () {
        return names.join(nameSeparator);
      }; // Return


      return names;
    }
    /**
    Get the name of our instance.
    If the name was never configured, then return the name in the format of `'${this.type} ${Math.random()}'` to output something like `task 0.2123`
    @type {String}
    @access public
    */

  }, {
    key: "name",
    get: function get() {
      return this.config.name || this.state.name || (this.state.name = "".concat(this.type, " ").concat(Math.random()));
    }
  }], [{
    key: "create",
    value: function create() {
      for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        args[_key2] = arguments[_key2];
      }

      return _construct(this, args);
    }
  }]);

  return BaseInterface;
}(require('events').EventEmitter); // Exports


module.exports = {
  BaseInterface: BaseInterface
};