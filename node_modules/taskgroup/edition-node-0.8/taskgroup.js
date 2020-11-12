/* eslint no-extra-parens:0 no-warning-comments:0 */
'use strict'; // Imports

function isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function _construct(Parent, args, Class) { if (isNativeReflectConstruct()) { _construct = Reflect.construct; } else { _construct = function _construct(Parent, args, Class) { var a = [null]; a.push.apply(a, args); var Constructor = Function.bind.apply(Parent, a); var instance = new Constructor(); if (Class) _setPrototypeOf(instance, Class.prototype); return instance; }; } return _construct.apply(null, arguments); }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance"); }

function _iterableToArray(iter) { if (Symbol.iterator in Object(iter) || Object.prototype.toString.call(iter) === "[object Arguments]") return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = new Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } }

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

var _require = require('./interface.js'),
    BaseInterface = _require.BaseInterface;

var _require2 = require('./task.js'),
    Task = _require2.Task;

var _require3 = require('./util.js'),
    queue = _require3.queue,
    ensureArray = _require3.ensureArray;

var extendr = require('extendr');

var eachr = require('eachr');

var unbounded = require('unbounded');
/**
Our TaskGroup class.

Available configuration is documented in {@link TaskGroup#setConfig}.

Available events:

- `pending()` - emitted when execution has been triggered
- `running()` - emitted when the first item starts execution
- `failed(error)` - emitted when execution exited with a failure
- `passed()` - emitted when execution exited with a success
- `completed(error, result)` - emitted when execution exited, `result` is an {?Array} of the result arguments for each item that executed
- `error(error)` - emtited if an unexpected error occured within ourself
- `done(error, result)` - emitted when either the execution completes (the `completed` event) or when an unexpected error occurs (the `error` event)
- `item.*(...)` - bubbled events from an added item
- `task.*(...)` - bubbled events from an added {Task}
- `group.*(...)` - bubbled events from an added {TaskGroup}

Available internal statuses:

- `'created'` - execution has not yet started
- `'pending'` - execution has been triggered
- `'running'` - execution of items has begun
- `'failed'` - execution has exited with failure status
- `'passed'` - execution has exited with success status
- `'destroyed'` - we've been destroyed and can no longer execute

@constructor
@class TaskGroup
@extends BaseInterface
@access public
*/


var TaskGroup =
/*#__PURE__*/
function (_BaseInterface) {
  _inherits(TaskGroup, _BaseInterface);

  function TaskGroup() {
    var _this3;

    var _this;

    _classCallCheck(this, TaskGroup);

    _this = _possibleConstructorReturn(this, _getPrototypeOf(TaskGroup).call(this)); // Prepare (used for class extensions)

    if (_this.prepare) {
      var _this2;

      (_this2 = _this).prepare.apply(_this2, arguments);
    } // State defaults


    extendr.defaults(_this.state, {
      result: null,
      error: null,
      status: 'created',
      itemsRemaining: [],
      itemsExecutingCount: 0,
      itemsDoneCount: 0
    }); // Configuration defaults

    extendr.defaults(_this.config, {
      // Standard
      storeResult: null,
      destroyOnceDone: true,
      parent: null,
      // Unique to TaskGroup
      method: null,
      abortOnError: true,
      destroyDoneItems: true,
      nestedTaskConfig: {},
      nestedTaskGroupConfig: {},
      emitNestedEvents: false,
      concurrency: 1,
      run: null
    }); // Apply user configuration

    (_this3 = _this).setConfig.apply(_this3, arguments); // Give setConfig enough chance to fire
    // Changing this to setImmediate breaks a lot of things
    // As tasks inside nested taskgroups will fire in any order


    queue(unbounded.binder.call(_this.autoRun, _assertThisInitialized(_this)));
    return _this;
  } // ===================================
  // Typing Helpers

  /**
  The type of our class.
  Used for the purpose of duck typing which is needed when working with node virtual machines
  as instanceof will not work in those environments.
  @type {String}
  @default 'taskgroup'
  @access private
  */


  _createClass(TaskGroup, [{
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
      this.state.result = null; // Chain

      return this;
    }
    /**
    Remove and destroy the remaining items.
    @chainable
    @returns {number} the amount of items that were dropped
    @access public
    */

  }, {
    key: "clearRemaining",
    value: function clearRemaining() {
      var dropped = 0;
      var itemsRemaining = this.state.itemsRemaining;

      while (itemsRemaining.length !== 0) {
        itemsRemaining.pop().destroy();
        ++dropped;
      } // Return


      return dropped;
    }
    /**
    Remove and destroy the running items. Here for verboseness.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "clearRunning",
    value: function clearRunning() {
      var error = new Error('Clearing running items is not possible. Instead remaining items and wait for running items to complete.');
      this.emit('error', error);
      return this;
    } // ===================================
    // Initialization

    /**
    Autorun ourself under certain conditions.
    	Those conditions being:
    	- if we the :method configuration is defined, and we have no :parent
    - if we the :run configuration is `true`
    	Used primarily to cause the :method to fire at the appropriate time when using inline style.
    	@chainable
    @returns {this}
    @access private
    */

  }, {
    key: "autoRun",
    value: function autoRun() {
      // Prepare
      var method = this.config.method;
      var run = this.config.run; // Auto run if we are going the inline style and have no parent

      if (method) {
        // Add the function as our first unamed task with the extra arguments
        this.addMethod(method); // If we are the topmost group default run to true

        if (!this.config.parent && run == null) {
          this.state.run = run = true;
        }
      } // Auto run if we are configured to


      if (run) {
        this.run();
      } // Chain


      return this;
    }
    /**
    Set the configuration for our instance.
    	Despite accepting an {Object} of configuration, we can also accept an {Array} of configuration.
    When using an array, a {String} becomes the :name, a {Function} becomes the :method, and an {Object} becomes the :config
    	@param {Object} [config]
    	@param {String} [config.name] - What we would like our name to be, useful for debugging
    @param {Function} [config.done] - Passed to {@link TaskGroup#onceDone} (aliases are `onceDone`, and `next`)
    @param {Function} [config.whenDone] - Passed to {@link TaskGroup#whenDone}
    @param {Object} [config.on] - An object of event names linking to listener functions that we would like bounded via {@link EventEmitter#on}
    @param {Object} [config.once] - An object of event names linking to listener functions that we would like bounded via {@link EventEmitter#once}
    	@param {Boolean} [config.storeResult] - Whether or not to store the result, if `false` will not store, defaults to `false` if `destroyOnceDone` is `true`
    @param {Boolean} [config.destroyOnceDone=true] - Whether or not we should automatically destroy the {TaskGroup} once done to free up resources
    @param {TaskGroup} [config.parent] - A parent {TaskGroup} that we may be attached to
    	@param {Function} [config.method] - The {Function} to execute for our {TaskGroup} when using inline execution style
    @param {Boolean} [config.abortOnError=true] - Whether or not we should abort execution of the {TaskGroup} and exit when an error occurs
    @param {Boolean} [config.destroyDoneItems=true] - Whether or not we should automatically destroy done items to free up resources
    @param {Object} [config.nestedTaskGroupConfig] - The nested configuration to be applied to all {TaskGroup} descendants of this group
    @param {Object} [config.nestedTaskConfig] - The nested configuration to be applied to all {Task} descendants of this group
    @param {Boolean} [config.emitNestedEvents=false] - Whether or not we should emit nested item events @TODO remove this, there are not tests for it, can be accomplished via item.add listener like TaskGroupDebug
    @param {Number} [config.concurrency=1] - The amount of items that we would like to execute at the same time. Use `0` for unlimited. `1` accomplishes serial execution, everything else accomplishes parallel execution
    @param {Boolean} [config.run] - A {Boolean} for whether or not to run the TaskGroup automatically, by default will be enabled if config.method is defined
    	@param {Array} [config.tasks] - An {Array} of {Task} instances to be added to this group
    @param {Array} [config.taskgroups] - An {Array} of {TaskGroup} instances to be added to this group
    @param {Array} [config.items] - An {Array} of {Task} and/or {TaskGroup} instances to be added to this group
    	@chainable
    @returns {this}
    @access public
    */

  }, {
    key: "setConfig",
    value: function setConfig() {
      var _this4 = this;

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
            extendr.deep(opts, arg); // @TODO why deep?

            break;

          default:
            {
              throw new Error("Unknown argument type of [".concat(type, "] given to TaskGroup::setConfig()"));
            }
        }
      }); // Apply the configuration directly to our instance

      eachr(opts, function (value, key) {
        if (value == null) return;

        switch (key) {
          case 'on':
            eachr(value, function (value, key) {
              if (value) _this4.on(key, value);
            });
            break;

          case 'once':
            eachr(value, function (value, key) {
              if (value) _this4.once(key, value);
            });
            break;

          case 'whenDone':
            _this4.whenDone(value);

            break;

          case 'onceDone':
          case 'done':
          case 'next':
            _this4.done(value);

            break;

          case 'task':
          case 'tasks':
            _this4.addTasks(value);

            break;

          case 'group':
          case 'groups':
          case 'taskgroup':
          case 'taskgroups':
            _this4.addTaskGroups(value);

            break;

          case 'item':
          case 'items':
            _this4.addItems(value);

            break;

          case 'onError':
          case 'pauseOnError':
          case 'includeInResults':
          case 'sync':
          case 'timeout':
          case 'exit':
          case 'nestedConfig':
            throw new Error("Deprecated configuration property [".concat(key, "] given to TaskGroup::setConfig()"));

          default:
            _this4.config[key] = value;
            break;
        }
      }); // Chain

      return this;
    }
    /**
    Merge passed configuration into {config.nestedTaskConfig}.
    @param {Object} opts - The configuration to merge.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "setNestedTaskConfig",
    value: function setNestedTaskConfig(opts) {
      // Fetch and copy options to the state's nested task configuration
      extendr.deep(this.state.nestedTaskConfig, opts); // Chain

      return this;
    }
    /**
    Merge passed configuration into {config.nestedTaskGroupConfig}.
    @param {Object} opts - The configuration to merge.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "setNestedTaskGroupConfig",
    value: function setNestedTaskGroupConfig(opts) {
      // Fetch and copy options to the state's nested configuration
      extendr.deep(this.state.nestedTaskGroupConfig, opts); // Chain

      return this;
    } // ===================================
    // Items
    // ---------------------------------
    // TaskGroup Method

    /**
    Prepare the method and it's configuration, and add it as a task to be executed.
    @param {Function} method - The function we want to execute as the method of this TaskGroup.
    @param {Object} opts - Optional configuration for the task to be created for the method.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "addMethod",
    value: function addMethod(method) {
      var opts = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      method = unbounded.binder.call(method, this); // run the taskgroup method on the group, rather than itself

      method.isTaskGroupMethod = true;
      if (!opts.name) opts.name = 'taskgroup method for ' + this.name;
      if (!opts.args) opts.args = [this.addTaskGroup.bind(this), this.addTask.bind(this)];
      if (opts.storeResult == null) opts.storeResult = false; // by default, hide result for methods

      this.addTask(method, opts);
      return this;
    } // ---------------------------------
    // Add Item

    /**
    Adds a {Task|TaskGroup} instance and configures it from the arguments.
    @param {Task|TaskGroup} item - The instance to add.
    @param {...*} args - Arguments used to configure the {Task|TaskGroup} instance.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addItem",
    value: function addItem(item) {
      // Prepare
      var me = this; // Only add the item if it exists

      if (!item) return null; // Link our item to ourself

      var itemConfig = {
        parent: this
      }; // Extract

      var nestedTaskGroupConfig = this.config.nestedTaskGroupConfig;
      var nestedTaskConfig = this.config.nestedTaskConfig;
      var emitNestedEvents = this.config.emitNestedEvents;
      var isTask = Task.isTask(item);
      var isTaskGroup = TaskGroup.isTaskGroup(item); // Check

      if (!isTask && !isTaskGroup) {
        var error = new Error('Unknown item type');
        this.emit('error', error);
        return this;
      } // Nested configuration


      for (var _len2 = arguments.length, args = new Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
        args[_key2 - 1] = arguments[_key2];
      }

      if (isTask) item.setConfig.apply(item, [itemConfig, nestedTaskConfig].concat(args));else if (isTaskGroup) item.setConfig.apply(item, [itemConfig, {
        nestedTaskConfig: nestedTaskConfig,
        nestedTaskGroupConfig: nestedTaskGroupConfig
      }, nestedTaskGroupConfig].concat(args)); // Name default
      // @todo perhaps this can come after item.add emissions, in case the user wants to set the item name there,
      // however that is signficant complexity to test, so for now won't bother

      if (!item.config.name) {
        item.config.name = "".concat(item.type, " ").concat(this.totalItems + 1, " for [").concat(this.name, "]");
      } // Store Result Default
      // if the item is undecided, then inherit from our decision
      // @todo perhaps this can come after item.add emissions, in case the user wants to set the item name there,
      // however that is signficant complexity to test, so for now won't bother


      if (item.config.storeResult == null) {
        item.config.storeResult = this.config.storeResult;
      } // Add the item


      this.state.itemsRemaining.push(item); // When the item completes, update our state

      item.done(this.itemDoneCallbackUpdateState.bind(this, item)); // Bubble the nested events if desired

      if (emitNestedEvents) {
        item.events.forEach(function (event) {
          item.on(event, function () {
            for (var _len3 = arguments.length, args = new Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
              args[_key3] = arguments[_key3];
            }

            if (isTask) me.emit.apply(me, ["task.".concat(event), item].concat(args));else if (isTaskGroup) me.emit.apply(me, ["task.".concat(event), item].concat(args));
            me.emit.apply(me, ["item.".concat(event), item].concat(args));
          });
        });
      } // Emit


      if (isTask) this.emit('task.add', item);else if (isTaskGroup) this.emit('group.add', item);
      this.emit('item.add', item); // When the item completes, after user events have fired, continue with the next state

      item.done(this.itemDoneCallbackNextState.bind(this, item)); // We may be running and expecting items, if so, fire
      // @TODO determine if this should require a new run

      this.fire(); // Chain

      return this;
    }
    /**
    Adds {Task|TaskGroup} instances and configures them from the arguments.
    @param {Array} items - Array of {Task|TaskGroup} instances to add to this task group.
    @param {...*} args - Arguments used to configure the {Task|TaskGroup} instances.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addItems",
    value: function addItems(items) {
      var _this5 = this;

      for (var _len4 = arguments.length, args = new Array(_len4 > 1 ? _len4 - 1 : 0), _key4 = 1; _key4 < _len4; _key4++) {
        args[_key4 - 1] = arguments[_key4];
      }

      ensureArray(items).forEach(function (item) {
        return _this5.addItem.apply(_this5, [item].concat(args));
      });
      return this;
    } // ---------------------------------
    // Add Task

    /**
    Creates a {Task} instance and configures it from the arguments.
    If the first argument is already a {Task} instance, then we configure it with the remaining arguments, instead of creating a new {Task} instance.
    @param {...*} args - Arguments used to configure the {Task} instance.
    @return {Task}
    @access public
    */

  }, {
    key: "createTask",
    value: function createTask() {
      // Prepare
      var task; // Support receiving an existing task instance

      for (var _len5 = arguments.length, args = new Array(_len5), _key5 = 0; _key5 < _len5; _key5++) {
        args[_key5] = arguments[_key5];
      }

      if (Task.isTask(args[0])) {
        var _task;

        task = args[0];

        (_task = task).setConfig.apply(_task, _toConsumableArray(args.slice(1)));
      } // Support receiving arguments to create a task instance
      else {
          task = _construct(this.Task, args);
        } // Return the new task


      return task;
    }
    /**
    Adds a {Task} instance and configures it from the arguments.
    If a {Task} instance is not supplied, a {Task} instance is created from the arguments.
    @param {...*} args - Arguments used to configure the {Task} instance.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addTask",
    value: function addTask() {
      var task = this.createTask.apply(this, arguments);
      this.addItem(task);
      return this;
    }
    /**
    Adds {Task} instances and configures them from the arguments.
    @param {Array} items - Array of {Task} instances to add to this task group.
    @param {...*} args - Arguments used to configure the {Task} instances.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addTasks",
    value: function addTasks(items) {
      var _this6 = this;

      for (var _len6 = arguments.length, args = new Array(_len6 > 1 ? _len6 - 1 : 0), _key6 = 1; _key6 < _len6; _key6++) {
        args[_key6 - 1] = arguments[_key6];
      }

      ensureArray(items).forEach(function (item) {
        return _this6.addTask.apply(_this6, [item].concat(args));
      });
      return this;
    } // ---------------------------------
    // Add Group

    /**
    Creates a {TaskGroup} instance and configures it from the arguments.
    If the first argument is already a {TaskGroup} instance, then we configure it with the remaining arguments, instead of creating a new {TaskGroup} instance.
    @param {...*} args - Arguments used to configure the {TaskGroup} instance.
    @return {TaskGroup}
    @access public
    */

  }, {
    key: "createTaskGroup",
    value: function createTaskGroup() {
      // Prepare
      var group; // Support receiving an existing group instance

      for (var _len7 = arguments.length, args = new Array(_len7), _key7 = 0; _key7 < _len7; _key7++) {
        args[_key7] = arguments[_key7];
      }

      if (TaskGroup.isTaskGroup(args[0])) {
        var _group;

        group = args[0];

        (_group = group).setConfig.apply(_group, _toConsumableArray(args.slice(1)));
      } // Support receiving arguments to create a group instance
      else {
          group = _construct(this.TaskGroup, args);
        } // Return the new group


      return group;
    }
    /**
    Adds a {TaskGroup} instance and configures it from the arguments.
    If a {TaskGroup} instance is not supplied, a {TaskGroup} instance is created from the arguments.
    @param {...*} args - Arguments used to configure the {TaskGroup} instance.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addTaskGroup",
    value: function addTaskGroup() {
      var group = this.createTaskGroup.apply(this, arguments);
      this.addItem(group);
      return this;
    }
    /**
    Adds {TaskGroup} instances and configures them from the arguments.
    @param {Array} items - Array of {TaskGroup} instances to add to this task group.
    @param {...*} args - Arguments used to configure the {TaskGroup} instances.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "addTaskGroups",
    value: function addTaskGroups(items) {
      var _this7 = this;

      for (var _len8 = arguments.length, args = new Array(_len8 > 1 ? _len8 - 1 : 0), _key8 = 1; _key8 < _len8; _key8++) {
        args[_key8 - 1] = arguments[_key8];
      }

      ensureArray(items).forEach(function (item) {
        return _this7.addTaskGroup.apply(_this7, [item].concat(args));
      });
      return this;
    } // ===================================
    // Workflow

    /**
    Fire the next items.
    @return {Array|false} Either an {Array} of items that were fired or `false` if no items were fired.
    @access private
    */

  }, {
    key: "fireNextItems",
    value: function fireNextItems() {
      // Prepare
      var items = []; // Fire the next items

      /* eslint no-constant-condition:0 */

      while (true) {
        var item = this.fireNextItem();

        if (item) {
          items.push(item);
        } else {
          break;
        }
      } // Return the items or false if no items


      var result = items.length !== 0 ? items : false;
      return result;
    }
    /**
    Fire the next item.
    @return {Task|TaskGroup|false} Either the {Task|TaskGroup} item that was fired or `false` if no item was fired.
    @access private
    */

  }, {
    key: "fireNextItem",
    value: function fireNextItem() {
      // Prepare
      var result = false; // Can we run the next item?

      if (this.shouldFire) {
        // Fire the next item
        // Update our status and notify our listeners
        if (this.state.status !== 'running') {
          this.state.status = 'running';
          this.emit('running');
        } // Get the next item and bump the running count


        var item = this.state.itemsRemaining.shift();
        ++this.state.itemsExecutingCount;
        item.run(); // Return the item

        result = item;
      } // Return


      return result;
    }
    /**
    What to do when an item is done. Run before user events.
    @chainable
    @returns {this}
    @param {Task|TaskGroup} item - The item that has completed
    @param {...*} args - The arguments that the item completed with.
    @access private
    */

  }, {
    key: "itemDoneCallbackUpdateState",
    value: function itemDoneCallbackUpdateState(item) {
      // Prepare
      var result = this.state.result; // Update error if it exists

      for (var _len9 = arguments.length, args = new Array(_len9 > 1 ? _len9 - 1 : 0), _key9 = 1; _key9 < _len9; _key9++) {
        args[_key9 - 1] = arguments[_key9];
      }

      if (this.config.abortOnError && args[0]) {
        if (!this.state.error) {
          this.state.error = args[0];
        }
      } // Add the result if desired


      if (this.storeResult && item.storeResult) {
        result.push(args);
      } // Mark that one less item is running and one more item done


      --this.state.itemsExecutingCount;
      ++this.state.itemsDoneCount; // Chain

      return this;
    }
    /**
    What to do when an item is done. Run after user events.
    @chainable
    @returns {this}
    @param {Task|TaskGroup} item - The item that has completed
    @access private
    */

  }, {
    key: "itemDoneCallbackNextState",
    value: function itemDoneCallbackNextState(item) {
      // As we no longer have any use for this item, as it has completed, destroy the item if desired
      if (this.config.destroyDoneItems) {
        item.destroy();
      } // Fire


      this.fire(); // Chain

      return this;
    }
    /**
    Set our task to the completed state.
    @NOTE This doesn't have to be a separate method, it could just go inside `fire` however, it is nice to have here to keep `fire` simple
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "finish",
    value: function finish() {
      // Set and emmit the appropriate status for our error or non-error
      var error = this.state.error;
      var status = error ? 'failed' : 'passed';
      this.state.status = status;
      this.emit(status, error); // Notity our listners we have completed

      var args = [error];
      if (this.state.result) args.push(this.state.result);
      this.emit.apply(this, ['completed'].concat(args)); // Prevent the error from persisting

      this.state.error = null; // Destroy if desired

      if (this.config.destroyOnceDone) {
        this.destroy();
      }
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
      this.emit('destroyed'); // Clear remaining items to prevent them from running

      this.clearRemaining(); // Clear result

      this.resetResult(); // Remove listeners

      this.removeAllListeners(); // Chain

      return this;
    }
    /**
    Internal: Either execute the reamining items we are not paused, or complete execution by exiting.
    @chainable
    @returns {this}
    @access private
    */

  }, {
    key: "fire",
    value: function fire() {
      // Have we started are not destroyed?
      if (this.started && this.state.status !== 'destroyed') {
        // Check if we are complete, if so, exit
        if (this.completed) {
          // Finish up
          this.finish();
        } // Otherwise continue firing items if we are wanting to pause
        else if (!this.shouldPause) {
            this.fireNextItems();
          }
      } // Chain


      return this;
    }
    /**
    Start/restart/resume the execution of the TaskGroup.
    @chainable
    @returns {this}
    @access public
    */

  }, {
    key: "run",
    value: function run() {
      var _this8 = this;

      // Prevent running on destroy
      if (this.state.status === 'destroyed') {
        var error = new Error("Invalid run status for the TaskGroup [".concat(this.names, "], it was [").concat(this.state.status, "]."));
        this.emit('error', error);
        return this;
      } // Put it into pending state


      this.state.status = 'pending';
      this.emit('pending'); // Prepare result, if it doesn't exist

      if (this.storeResult && this.state.result == null) {
        this.state.result = [];
      } // Queue the actual running so we can give time for the listeners to complete before continuing


      queue(function () {
        return _this8.fire();
      }); // Chain

      return this;
    }
  }, {
    key: "type",
    get: function get() {
      return 'taskgroup';
    }
    /**
    A helper method to check if the passed argument is a {TaskGroup} via instanceof and duck typing.
    @param {TaskGroup} group - The possible instance of the {TaskGroup} that we want to check
    @return {Boolean} Whether or not the item is a {TaskGroup} instance.
    @static
    @access public
    */

  }, {
    key: "Task",

    /**
    A reference to the {Task} class for use in {@link TaskGroup#createTask} if we want to override it.
    @type {Task}
    @default Task
    @access public
    */
    get: function get() {
      return Task;
    }
    /**
    A reference to the {TaskGroup} class for use in {@link TaskGroup#createTaskGroup} if we want to override it.
    @type {TaskGroup}
    @default TaskGroup
    @access public
    */

  }, {
    key: "TaskGroup",
    get: function get() {
      return TaskGroup;
    } // ===================================
    // Accessors

    /**
    An {Array} of the events that we may emit.
    @type {Array}
    @access protected
    */

  }, {
    key: "events",
    get: function get() {
      return ['error', 'pending', 'running', 'passed', 'failed', 'completed', 'done', 'destroyed'];
    }
    /**
    Fetches the interpreted value of storeResult
    @type {boolean}
    @access private
    */

  }, {
    key: "storeResult",
    get: function get() {
      var _this$config = this.config,
          storeResult = _this$config.storeResult,
          destroyOnceDone = _this$config.destroyOnceDone;
      return storeResult == null ? destroyOnceDone : storeResult !== false;
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
    A {String} containing our current status. See our {TaskGroup} description for available values.
    @type {String}
    @access protected
    */

  }, {
    key: "status",
    get: function get() {
      return this.state.status;
    }
    /**
    An {Array} that contains the result property for each completed {Task} and {TaskGroup}.
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
    Gets the total number of items inside our task group.
    @type {Number}
    @access public
    */

  }, {
    key: "totalItems",
    get: function get() {
      var remaining = this.state.itemsRemaining.length;
      var executing = this.state.itemsExecutingCount;
      var done = this.state.itemsDoneCount;
      var total = executing + remaining + done;
      return total;
    }
    /**
    Gets the total number count of each of our item lists.
    	Returns an {Object} containg the hashes:
    	- remaining - A {Number} of the names of the remaining items.
    - executing - A {Number} of the names of the executing items.
    - done - A {Number} of the names of the done items.
    - total - A {Number} of the total items we have.
    - result - A {Number} of the total results we have.
    	@type {Object}
    @access public
    */

  }, {
    key: "itemTotals",
    get: function get() {
      var remaining = this.state.itemsRemaining.length;
      var executing = this.state.itemsExecutingCount;
      var done = this.state.itemsDoneCount;
      var result = this.state.result && this.state.result.length;
      var total = executing + remaining + done;
      return {
        remaining: remaining,
        executing: executing,
        done: done,
        total: total,
        result: result
      };
    }
    /**
    Whether or not we have any items yet to execute.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasRemaining",
    get: function get() {
      return this.state.itemsRemaining.length !== 0;
    }
    /**
    Whether or not we have any running items.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasRunning",
    get: function get() {
      return this.state.itemsExecutingCount !== 0;
    }
    /**
    Whether or not we have any items running or remaining.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasItems",
    get: function get() {
      return this.hasRunning || this.hasRemaining;
    }
    /**
    Whether or not we have an error.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasError",
    get: function get() {
      return this.state.error != null;
    }
    /**
    Whether or not we have an error or a result.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasResult",
    get: function get() {
      return this.hasError || this.state.result.length !== 0;
    }
    /**
    Whether or not we have any available slots to execute more items.
    @type {Boolean}
    @access private
    */

  }, {
    key: "hasSlots",
    get: function get() {
      var concurrency = this.config.concurrency;
      return concurrency === 0 || this.state.itemsExecutingCount < concurrency;
    }
    /**
    Whether or not we are capable of firing more items.
    This is determined whether or not we are not paused, and we have remaning items, and we have slots able to execute those remaning items.
    @type {Boolean}
    @access private
    */

  }, {
    key: "shouldFire",
    get: function get() {
      return !this.shouldPause && this.hasRemaining && this.hasSlots;
    }
    /**
    Whether or not we have errord and want to pause when we have an error.
    @type {Boolean}
    @access private
    */

  }, {
    key: "shouldPause",
    get: function get() {
      return this.config.abortOnError && this.hasError;
    }
    /**
    Whether or not we execution is currently paused.
    @type {Boolean}
    @access private
    */

  }, {
    key: "paused",
    get: function get() {
      return this.shouldPause && !this.hasRunning;
    }
    /**
    Whether or not we have no running or remaining items left.
    @type {Boolean}
    @access private
    */

  }, {
    key: "empty",
    get: function get() {
      return !this.hasItems;
    }
    /**
    Whether or not we have finished execution.
    @type {Boolean}
    @access private
    */

  }, {
    key: "exited",
    get: function get() {
      switch (this.state.status) {
        case 'passed':
        case 'failed':
        case 'destroyed':
          return true;

        default:
          return false;
      }
    }
    /**
    Whether or not we have started execution.
    @type {Boolean}
    @access private
    */

  }, {
    key: "started",
    get: function get() {
      return this.state.status !== 'created';
    }
    /**
    Whether or not we execution has completed.
    Completion of executed is determined of whether or not we have started, and whether or not we are currently paused or have no remaining and running items left
    @type {Boolean}
    @access private
    */

  }, {
    key: "completed",
    get: function get() {
      return this.started && (this.paused || this.empty);
    }
  }], [{
    key: "isTaskGroup",
    value: function isTaskGroup(group) {
      return group && group.type === 'taskgroup' || group instanceof this;
    }
  }]);

  return TaskGroup;
}(BaseInterface); // Export


module.exports = {
  TaskGroup: TaskGroup
};