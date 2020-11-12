/* eslint no-extra-parens:0 func-style:0 */
'use strict'; // Imports

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance"); }

function _iterableToArray(iter) { if (Symbol.iterator in Object(iter) || Object.prototype.toString.call(iter) === "[object Arguments]") return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = new Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } }

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

var _require = require('./interface.js'),
    BaseInterface = _require.BaseInterface;

var _require2 = require('./util.js'),
    queue = _require2.queue,
    domain = _require2.domain;

var ambi = require('ambi');

var extendr = require('extendr');

var eachr = require('eachr');

var unbounded = require('unbounded');
/**
Our Task Class

Available configuration is documented in {@link Task#setConfig}.

Available events:

- `pending()` - emitted when execution has been triggered
- `running()` - emitted when the method starts execution
- `failed(error)` - emitted when execution exited with a failure
- `passed()` - emitted when execution exited with a success
- `completed(error, ...resultArguments)` - emitted when execution exited, `resultArguments` are the result arguments from the method
- `error(error)` - emtited if an unexpected error occurs without ourself
- `done(error, ...resultArguments)` - emitted when either execution completes (the `completed` event) or when an unexpected error occurs (the `error` event)

Available internal statuses:

- `'created'` - execution has not yet started
- `'pending'` - execution has been triggered
- `'running'` - execution of our method has begun
- `'failed'` - execution of our method has failed
- `'passed'` - execution of our method has succeeded
- `'destroyed'` - we've been destroyed and can no longer execute

@example
const Task = require('taskgroup').Task

Task.create('my synchronous task', function () {
	return 5
}).done(console.info).run()  // [null, 5]

Task.create('my asynchronous task', function (complete) {
	complete(null, 5)
}).done(console.info).run()  // [null, 5]

Task.create('my task that returns an error', function () {
	var error = new Error('deliberate error')
	return error
}).done(console.info).run()  // [Error('deliberator error')]

Task.create('my task that passes an error', function (complete) {
	var error = new Error('deliberate error')
	complete(error)
}).done(console.info).run()  // [Error('deliberator error')]

@class Task
@extends BaseInterface
@constructor
@access public
*/


var Task =
/*#__PURE__*/
function (_BaseInterface) {
  _inherits(Task, _BaseInterface);

  function Task() {
    var _this2;

    var _this;

    _classCallCheck(this, Task);

    // Initialise BaseInterface
    _this = _possibleConstructorReturn(this, _getPrototypeOf(Task).call(this)); // State defaults

    extendr.defaults(_this.state, {
      result: null,
      error: null,
      status: 'created'
    }); // Configuration defaults

    extendr.defaults(_this.config, {
      // Standard
      storeResult: null,
      destroyOnceDone: true,
      parent: null,
      // Unique to Task
      method: null,
      errorOnExcessCompletions: true,
      ambi: true,
      domain: null,
      args: null
    }); // Apply user configuration

    (_this2 = _this).setConfig.apply(_this2, arguments);

    return _this;
  } // ===================================
  // Typing Helpers

  /**
  The type of our class.
  	Used for the purpose of duck typing
  which is needed when working with node virtual machines
  as instanceof will not work in those environments.
  	@type {String}
  @default 'task'
  @access private
  */


  _createClass(Task, [{
    key: "resetResult",
    // ---------------------------------
    // State Changers

    /**
    Reset the result.
    At this point this method is internal, as it's functionality may change in the future, and it's outside use is not yet confirmed. If you need such an ability, let us know via the issue tracker.
    @chainable
    @returns {this}
    @access private
    */
    value: function resetResult() {
      this.state.result = null;
      return this;
    }
    /**
    Clear the domain
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "clearDomain",
    value: function clearDomain() {
      var taskDomain = this.state.taskDomain;

      if (taskDomain) {
        taskDomain.exit();
        taskDomain.removeAllListeners();
        this.state.taskDomain = null;
      }

      return this;
    } // ===================================
    // Initialization

    /**
    Set the configuration for our instance.
    	@param {Object} [config]
    	@param {String} [config.name] - What we would like our name to be, useful for debugging.
    @param {Function} [config.done] - Passed to {@link Task#onceDone} (aliases are `onceDone`, and `next`)
    @param {Function} [config.whenDone] - Passed to {@link Task#whenDone}
    @param {Object} [config.on] - A map of event names linking to listener functions that we would like bounded via {EventEmitter.on}
    @param {Object} [config.once] - A map of event names linking to listener functions that we would like bounded via {EventEmitter.once}
    	@param {Boolean} [config.storeResult] - Whether or not to store the result, if `false` will not store
    @param {Boolean} [config.destroyOnceDone=true] - Whether or not to automatically destroy the task once it's done to free up resources
    @param {TaskGroup} [config.parent] - A parent {@link TaskGroup} that we may be attached to
    	@param {Function} [config.method] - The {Function} to execute for our {Task}
    @param {Boolean} [config.errorOnExcessCompletions=true] - Whether or not to error if the task completes more than once
    @param {Boolean} [config.ambi=true] - Whether or not to use bevry/ambi to determine if the method is asynchronous or synchronous and execute it appropriately
    @param {Boolean} [config.domain] - If not `false` will wrap the task execution in a domain to attempt to catch background errors (aka errors that are occuring in other ticks than the initial execution), if `true` will fail if domains aren't available
    @param {Array} [config.args] - Arguments that we would like to forward onto our method when we execute it
    	@chainable
    @returns {this}
    @access public
    */

  }, {
    key: "setConfig",
    value: function setConfig() {
      var _this3 = this;

      var opts = {}; // Extract the configuration from the arguments

      for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      args.forEach(function (arg) {
        if (arg == null) return;

        var type = _typeof(arg);

        switch (type) {
          case 'string':
            opts.name = arg;
            break;

          case 'function':
            opts.method = arg;
            break;

          case 'object':
            extendr.deep(opts, arg);
            break;

          default:
            {
              throw new Error("Unknown argument type of [".concat(type, "] given to Task::setConfig()"));
            }
        }
      }); // Apply the configuration directly to our instance

      eachr(opts, function (value, key) {
        if (value == null) return;

        switch (key) {
          case 'on':
            eachr(value, function (value, key) {
              if (value) _this3.on(key, value);
            });
            break;

          case 'once':
            eachr(value, function (value, key) {
              if (value) _this3.once(key, value);
            });
            break;

          case 'whenDone':
            _this3.whenDone(value);

            break;

          case 'onceDone':
          case 'done':
          case 'next':
            _this3.onceDone(value);

            break;

          case 'onError':
          case 'pauseOnError':
          case 'includeInResults':
          case 'sync':
          case 'timeout':
          case 'exit':
            throw new Error("Deprecated configuration property [".concat(key, "] given to Task::setConfig()"));

          default:
            _this3.config[key] = value;
            break;
        }
      }); // Chain

      return this;
    } // ===================================
    // Workflow

    /**
    What to do when our task method completes.
    Should only ever execute once, if it executes more than once, then we error.
    @param {...*} args - The arguments that will be applied to the {@link Task#result} variable. First argument is the {Error} if it exists.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "itemCompletionCallback",
    value: function itemCompletionCallback() {
      // Store the first error
      var error = this.state.error;

      for (var _len2 = arguments.length, args = new Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        args[_key2] = arguments[_key2];
      }

      if (args[0] && !error) {
        this.state.error = error = args[0];
      } // Complete for the first (and hopefully only) time


      if (!this.exited) {
        // Apply the result if we want to and it exists
        if (this.storeResult) {
          this.state.result = args.slice(1);
        }
      } // Finish up


      this.finish(); // Chain

      return this;
    }
    /**
    @NOTE Perhaps at some point, we can add abort/exit functionality, but these things have to be considered:
    What will happen to currently running items?
    What will happen to remaining items?
    Should it be two methods? .halt() and .abort(error?)
    Should it be a state?
    Should it alter the state?
    Should it clear or destroy?
    What is the definition of pausing with this?
    Perhaps we need to update the definition of pausing to be halted instead?
    How can we apply this to Task and TaskGroup consistently?
    @access private
    @returns {void}
    */

  }, {
    key: "abort",
    value: function abort() {
      throw new Error('not yet implemented');
    }
    /**
    Set our task to the completed state.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "finish",
    value: function finish() {
      var error = this.state.error; // Complete for the first (and hopefully only) time

      if (!this.exited) {
        // Set the status and emit depending on success or failure status
        var status = error ? 'failed' : 'passed';
        this.state.status = status;
        this.emit(status, error); // Notify our listeners we have completed

        var args = [error];
        if (this.state.result) args.push.apply(args, _toConsumableArray(this.state.result));
        this.emit.apply(this, ['completed'].concat(args)); // Prevent the error from persisting

        this.state.error = null; // Destroy if desired

        if (this.config.destroyOnceDone) {
          this.destroy();
        }
      } // Error as we have already completed before
      else if (this.config.errorOnExcessCompletions) {
          var source = (this.config.method.unbounded || this.config.method || 'no longer present').toString();
          var completedError = new Error("The task [".concat(this.names, "] just completed, but it had already completed earlier, this is unexpected.\nTask Source: ").concat(source));
          this.emit('error', completedError);
        } // Chain


      return this;
    }
    /**
    Destroy ourself and prevent ourself from executing ever again.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "destroy",
    value: function destroy() {
      // Update our status and notify our listeners
      this.state.status = 'destroyed';
      this.emit('destroyed'); // Clear the domain

      this.clearDomain(); // Clear result, in case it keeps references to something

      this.resetResult(); // Remove all listeners

      this.removeAllListeners(); // Chain

      return this;
    }
    /**
    Fire the task method with our config arguments and wrapped in a domain.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "fire",
    value: function fire() {
      var _this4 = this;

      // Prepare
      var taskArgs = (this.config.args || []).slice();
      var taskDomain = this.state.taskDomain;
      var exitMethod = unbounded.binder.call(this.itemCompletionCallback, this);
      var method = this.config.method; // Check that we have a method to fire

      if (!method) {
        var error = new Error("The task [".concat(this.names, "] failed to run as no method was defined for it."));
        this.emit('error', error);
        return this;
      } // Bind method


      method = unbounded.binder.call(method, this); // Handle domains

      if (domain) {
        // Prepare the task domain if we want to and if it doesn't already exist
        if (!taskDomain && this.config.domain !== false) {
          this.state.taskDomain = taskDomain = domain.create();
          taskDomain.on('error', exitMethod);
        }
      } else if (this.config.domain === true) {
        var _error = new Error("The task [".concat(this.names, "] failed to run as it requested to use domains but domains are not available."));

        this.emit('error', _error);
        return this;
      } // Domains, as well as process.nextTick, make it so we can't just use exitMethod directly
      // Instead we cover it up like so, to ensure the domain exits, as well to ensure the arguments are passed


      var completeMethod = function completeMethod() {
        for (var _len3 = arguments.length, args = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
          args[_key3] = arguments[_key3];
        }

        if (taskDomain) {
          _this4.clearDomain();

          taskDomain = null;
          exitMethod.apply(void 0, args);
        } else {
          // Use the next tick workaround to escape the try...catch scope
          // Which would otherwise catch errors inside our code when it shouldn't therefore suppressing errors
          queue(function () {
            exitMethod.apply(void 0, args);
          });
        }
      }; // Our fire function that will be wrapped in a domain or executed directly


      var fireMethod = function fireMethod() {
        // Execute with ambi if appropriate
        if (_this4.config.ambi !== false) {
          ambi.apply(void 0, [method].concat(_toConsumableArray(taskArgs)));
        } // Otherwise execute directly if appropriate
        else {
            method.apply(void 0, _toConsumableArray(taskArgs));
          }
      }; // Add the competion callback to the arguments our method will receive


      taskArgs.push(completeMethod); // Notify that we are now running

      this.state.status = 'running';
      this.emit('running'); // Fire the method within the domain if desired, otherwise execute directly

      if (taskDomain) {
        taskDomain.run(fireMethod);
      } else {
        try {
          fireMethod();
        } catch (error) {
          exitMethod(error);
        }
      } // Chain


      return this;
    }
    /**
    Start the execution of the task.
    Will emit an `error` event if the task has already started before.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "run",
    value: function run() {
      var _this5 = this;

      // Already started?
      if (this.state.status !== 'created') {
        var error = new Error("Invalid run status for the Task [".concat(this.names, "], it was [").concat(this.state.status, "] instead of [created]."));
        this.emit('error', error);
        return this;
      } // Put it into pending state


      this.state.status = 'pending';
      this.emit('pending'); // Queue the actual running so we can give time for the listeners to complete before continuing

      queue(function () {
        return _this5.fire();
      }); // Chain

      return this;
    }
  }, {
    key: "type",
    get: function get() {
      return 'task';
    }
    /**
    A helper method to check if the passed argument is a {Task} via instanceof and duck typing.
    @param {Task} item - The possible instance of the {Task} that we want to check
    @return {Boolean} Whether or not the item is a {Task} instance.
    @static
    @access public
    */

  }, {
    key: "events",
    // ===================================
    // Accessors

    /**
    An {Array} of the events that we may emit.
    @type {Array}
    @default ['events', 'error', 'pending', 'running', 'failed', 'passed', 'completed', 'done', 'destroyed']
    @access protected
    */
    get: function get() {
      return ['events', 'error', 'pending', 'running', 'failed', 'passed', 'completed', 'done', 'destroyed'];
    }
    /**
    Fetches the interpreted value of storeResult
    @type {boolean}
    @access private
    */

  }, {
    key: "storeResult",
    get: function get() {
      return this.config.storeResult !== false;
    } // -----------------------------------
    // State Accessors

    /**
    The first {Error} that has occured.
    @type {Error}
    @access protected
    */

  }, {
    key: "error",
    get: function get() {
      return this.state.error;
    }
    /**
    A {String} containing our current status. See our {Task} description for available values.
    @type {String}
    @access protected
    */

  }, {
    key: "status",
    get: function get() {
      return this.state.status;
    }
    /**
    An {Array} representing the returned result or the passed {Arguments} of our method (minus the first error argument).
    If no result has occured yet, or we don't care, it is null.
    @type {?Array}
    @access protected
    */

  }, {
    key: "result",
    get: function get() {
      return this.state.result;
    } // ---------------------------------
    // Status Accessors

    /**
    Have we started execution yet?
    @type {Boolean}
    @access private
    */

  }, {
    key: "started",
    get: function get() {
      return this.state.status !== 'created';
    }
    /**
    Have we finished execution yet?
    @type {Boolean}
    @access private
    */

  }, {
    key: "exited",
    get: function get() {
      switch (this.state.status) {
        case 'failed':
        case 'passed':
        case 'destroyed':
          return true;

        default:
          return false;
      }
    }
    /**
    Have we completed execution yet?
    @type {Boolean}
    @access private
    */

  }, {
    key: "completed",
    get: function get() {
      switch (this.state.status) {
        case 'failed':
        case 'passed':
          return true;

        default:
          return false;
      }
    }
  }], [{
    key: "isTask",
    value: function isTask(item) {
      return item && item.type === 'task' || item instanceof this;
    }
  }]);

  return Task;
}(BaseInterface); // Exports


module.exports = {
  Task: Task
};