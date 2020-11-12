/* eslint no-extra-parens:0 func-style:0 */
'use strict'

// Imports
const { BaseInterface } = require('./interface.js')
const { queue, domain } = require('./util.js')
const ambi = require('ambi')
const extendr = require('extendr')
const eachr = require('eachr')
const unbounded = require('unbounded')

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
class Task extends BaseInterface {
	constructor(...args) {
		// Initialise BaseInterface
		super()

		// State defaults
		extendr.defaults(this.state, {
			result: null,
			error: null,
			status: 'created'
		})

		// Configuration defaults
		extendr.defaults(this.config, {
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
		})

		// Apply user configuration
		this.setConfig(...args)
	}

	// ===================================
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
	get type() {
		return 'task'
	}

	/**
	A helper method to check if the passed argument is a {Task} via instanceof and duck typing.
	@param {Task} item - The possible instance of the {Task} that we want to check
	@return {Boolean} Whether or not the item is a {Task} instance.
	@static
	@access public
	*/
	static isTask(item) {
		return (item && item.type === 'task') || item instanceof this
	}

	// ===================================
	// Accessors

	/**
	An {Array} of the events that we may emit.
	@type {Array}
	@default ['events', 'error', 'pending', 'running', 'failed', 'passed', 'completed', 'done', 'destroyed']
	@access protected
	*/
	get events() {
		return [
			'events',
			'error',
			'pending',
			'running',
			'failed',
			'passed',
			'completed',
			'done',
			'destroyed'
		]
	}

	/**
	Fetches the interpreted value of storeResult
	@type {boolean}
	@access private
	*/
	get storeResult() {
		return this.config.storeResult !== false
	}

	// -----------------------------------
	// State Accessors

	/**
	The first {Error} that has occured.
	@type {Error}
	@access protected
	*/
	get error() {
		return this.state.error
	}

	/**
	A {String} containing our current status. See our {Task} description for available values.
	@type {String}
	@access protected
	*/
	get status() {
		return this.state.status
	}

	/**
	An {Array} representing the returned result or the passed {Arguments} of our method (minus the first error argument).
	If no result has occured yet, or we don't care, it is null.
	@type {?Array}
	@access protected
	*/
	get result() {
		return this.state.result
	}

	// ---------------------------------
	// Status Accessors

	/**
	Have we started execution yet?
	@type {Boolean}
	@access private
	*/
	get started() {
		return this.state.status !== 'created'
	}

	/**
	Have we finished execution yet?
	@type {Boolean}
	@access private
	*/
	get exited() {
		switch (this.state.status) {
			case 'failed':
			case 'passed':
			case 'destroyed':
				return true

			default:
				return false
		}
	}

	/**
	Have we completed execution yet?
	@type {Boolean}
	@access private
	*/
	get completed() {
		switch (this.state.status) {
			case 'failed':
			case 'passed':
				return true

			default:
				return false
		}
	}

	// ---------------------------------
	// State Changers

	/**
	Reset the result.
	At this point this method is internal, as it's functionality may change in the future, and it's outside use is not yet confirmed. If you need such an ability, let us know via the issue tracker.
	@chainable
	@returns {this}
	@access private
	*/
	resetResult() {
		this.state.result = null
		return this
	}

	/**
	Clear the domain
	@chainable
	@returns {this}
	@access private
	*/
	clearDomain() {
		const taskDomain = this.state.taskDomain
		if (taskDomain) {
			taskDomain.exit()
			taskDomain.removeAllListeners()
			this.state.taskDomain = null
		}
		return this
	}

	// ===================================
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
	setConfig(...args) {
		const opts = {}

		// Extract the configuration from the arguments
		args.forEach(function(arg) {
			if (arg == null) return
			const type = typeof arg
			switch (type) {
				case 'string':
					opts.name = arg
					break
				case 'function':
					opts.method = arg
					break
				case 'object':
					extendr.deep(opts, arg)
					break
				default: {
					throw new Error(
						`Unknown argument type of [${type}] given to Task::setConfig()`
					)
				}
			}
		})

		// Apply the configuration directly to our instance
		eachr(opts, (value, key) => {
			if (value == null) return
			switch (key) {
				case 'on':
					eachr(value, (value, key) => {
						if (value) this.on(key, value)
					})
					break

				case 'once':
					eachr(value, (value, key) => {
						if (value) this.once(key, value)
					})
					break

				case 'whenDone':
					this.whenDone(value)
					break

				case 'onceDone':
				case 'done':
				case 'next':
					this.onceDone(value)
					break

				case 'onError':
				case 'pauseOnError':
				case 'includeInResults':
				case 'sync':
				case 'timeout':
				case 'exit':
					throw new Error(
						`Deprecated configuration property [${key}] given to Task::setConfig()`
					)

				default:
					this.config[key] = value
					break
			}
		})

		// Chain
		return this
	}

	// ===================================
	// Workflow

	/**
	What to do when our task method completes.
	Should only ever execute once, if it executes more than once, then we error.
	@param {...*} args - The arguments that will be applied to the {@link Task#result} variable. First argument is the {Error} if it exists.
	@chainable
	@returns {this}
	@access private
	*/
	itemCompletionCallback(...args) {
		// Store the first error
		let error = this.state.error
		if (args[0] && !error) {
			this.state.error = error = args[0]
		}

		// Complete for the first (and hopefully only) time
		if (!this.exited) {
			// Apply the result if we want to and it exists
			if (this.storeResult) {
				this.state.result = args.slice(1)
			}
		}

		// Finish up
		this.finish()

		// Chain
		return this
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
	abort() {
		throw new Error('not yet implemented')
	}

	/**
	Set our task to the completed state.
	@chainable
	@returns {this}
	@access private
	*/
	finish() {
		const error = this.state.error

		// Complete for the first (and hopefully only) time
		if (!this.exited) {
			// Set the status and emit depending on success or failure status
			const status = error ? 'failed' : 'passed'
			this.state.status = status
			this.emit(status, error)

			// Notify our listeners we have completed
			const args = [error]
			if (this.state.result) args.push(...this.state.result)
			this.emit('completed', ...args)

			// Prevent the error from persisting
			this.state.error = null

			// Destroy if desired
			if (this.config.destroyOnceDone) {
				this.destroy()
			}
		}

		// Error as we have already completed before
		else if (this.config.errorOnExcessCompletions) {
			const source = (
				this.config.method.unbounded ||
				this.config.method ||
				'no longer present'
			).toString()
			const completedError = new Error(
				`The task [${this.names}] just completed, but it had already completed earlier, this is unexpected.\nTask Source: ${source}`
			)
			this.emit('error', completedError)
		}

		// Chain
		return this
	}

	/**
	Destroy ourself and prevent ourself from executing ever again.
	@chainable
	@returns {this}
	@access public
	*/
	destroy() {
		// Update our status and notify our listeners
		this.state.status = 'destroyed'
		this.emit('destroyed')

		// Clear the domain
		this.clearDomain()

		// Clear result, in case it keeps references to something
		this.resetResult()

		// Remove all listeners
		this.removeAllListeners()

		// Chain
		return this
	}

	/**
	Fire the task method with our config arguments and wrapped in a domain.
	@chainable
	@returns {this}
	@access private
	*/
	fire() {
		// Prepare
		const taskArgs = (this.config.args || []).slice()
		let taskDomain = this.state.taskDomain
		const exitMethod = unbounded.binder.call(this.itemCompletionCallback, this)
		let method = this.config.method

		// Check that we have a method to fire
		if (!method) {
			const error = new Error(
				`The task [${this.names}] failed to run as no method was defined for it.`
			)
			this.emit('error', error)
			return this
		}

		// Bind method
		method = unbounded.binder.call(method, this)

		// Handle domains
		if (domain) {
			// Prepare the task domain if we want to and if it doesn't already exist
			if (!taskDomain && this.config.domain !== false) {
				this.state.taskDomain = taskDomain = domain.create()
				taskDomain.on('error', exitMethod)
			}
		} else if (this.config.domain === true) {
			const error = new Error(
				`The task [${this.names}] failed to run as it requested to use domains but domains are not available.`
			)
			this.emit('error', error)
			return this
		}

		// Domains, as well as process.nextTick, make it so we can't just use exitMethod directly
		// Instead we cover it up like so, to ensure the domain exits, as well to ensure the arguments are passed
		const completeMethod = (...args) => {
			if (taskDomain) {
				this.clearDomain()
				taskDomain = null
				exitMethod(...args)
			} else {
				// Use the next tick workaround to escape the try...catch scope
				// Which would otherwise catch errors inside our code when it shouldn't therefore suppressing errors
				queue(function() {
					exitMethod(...args)
				})
			}
		}

		// Our fire function that will be wrapped in a domain or executed directly
		const fireMethod = () => {
			// Execute with ambi if appropriate
			if (this.config.ambi !== false) {
				ambi(method, ...taskArgs)
			}

			// Otherwise execute directly if appropriate
			else {
				method(...taskArgs)
			}
		}

		// Add the competion callback to the arguments our method will receive
		taskArgs.push(completeMethod)

		// Notify that we are now running
		this.state.status = 'running'
		this.emit('running')

		// Fire the method within the domain if desired, otherwise execute directly
		if (taskDomain) {
			taskDomain.run(fireMethod)
		} else {
			try {
				fireMethod()
			} catch (error) {
				exitMethod(error)
			}
		}

		// Chain
		return this
	}

	/**
	Start the execution of the task.
	Will emit an `error` event if the task has already started before.
	@chainable
	@returns {this}
	@access public
	*/
	run() {
		// Already started?
		if (this.state.status !== 'created') {
			const error = new Error(
				`Invalid run status for the Task [${this.names}], it was [${this.state.status}] instead of [created].`
			)
			this.emit('error', error)
			return this
		}

		// Put it into pending state
		this.state.status = 'pending'
		this.emit('pending')

		// Queue the actual running so we can give time for the listeners to complete before continuing
		queue(() => this.fire())

		// Chain
		return this
	}
}

// Exports
module.exports = { Task }
