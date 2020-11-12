'use strict'

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
class BaseInterface extends require('events').EventEmitter {
	constructor() {
		super()

		// Allow extensions of this class to prepare the class instance before anything else fires
		if (this.prepare) {
			this.prepare()
		}

		// Set state and config
		if (this.state == null) this.state = {}
		if (this.config == null) this.config = {}
		if (this.config.nameSeparator == null) this.config.nameSeparator = ' ➞  '

		// Generate our listener method that we will beind to different events
		// to add support for the `done` event and better error/event handling
		function listener(event, ...args) {
			// Prepare
			const error = args[0]

			// has done listener, forward to that
			if (this.listeners('done').length !== 0) {
				this.emit('done', ...args)
			}

			// has error, but no done listener and no event listener, throw error
			else if (error && this.listeners(event).length === 1) {
				if (event === 'error') {
					throw error
				} else {
					this.emit('error', error)
				}
			}
		}

		// Listen to the different events without listener
		this.on('error', listener.bind(this, 'error'))
		this.on('completed', listener.bind(this, 'completed'))
		// this.on('halted', listener.bind(this, 'halted'))
		// ^ @TODO not yet implemented, would be an alternative to pausing
	}

	/**
	Creates and returns new instance of the current class.
	@param {...*} args - The arguments to be forwarded along to the constructor.
	@return {BaseInterface} The new instance.

	@static
	@access public
	*/
	static create(...args) {
		return new this(...args)
	}

	/**
	Attaches the listener to the `done` event to be emitted each time.
	@param {Function} listener - Attaches to the `done` event.
	@chainable
	@returns {BaseInterface} this
	@access public
	*/
	whenDone(listener) {
		// Attach the listener
		this.on('done', listener.bind(this))

		// Chain
		return this
	}

	/**
	Attaches the listener to the `done` event to be emitted only once, then removed to not fire again.
	@param {Function} listener - Attaches to the `done` event.
	@chainable
	@returns {BaseInterface} this
	@access public
	*/
	onceDone(listener) {
		// Attach the listener
		this.once('done', listener.bind(this))

		// Chain
		return this
	}

	/**
	Alias for {@link BaseInterface#onceDone}
	@param {Function} listener - Attaches to the `done` event.
	@chainable
	@returns {BaseInterface} this
	@access public
	*/
	done(listener) {
		return this.onceDone(listener)
	}

	/**
	Gets our name prepended by all of our parents names
	@type {Array}
	@access public
	*/
	get names() {
		// Fetch
		const names = [],
			{ name, parent, nameSeparator } = this.config
		if (parent) names.push(...parent.names)
		if (name !== false) names.push(this.name)
		names.toString = () => names.join(nameSeparator)

		// Return
		return names
	}

	/**
	Get the name of our instance.
	If the name was never configured, then return the name in the format of `'${this.type} ${Math.random()}'` to output something like `task 0.2123`
	@type {String}
	@access public
	*/
	get name() {
		return (
			this.config.name ||
			this.state.name ||
			(this.state.name = `${this.type} ${Math.random()}`)
		)
	}

	// ---------------------------------
	// Backwards compatability helpers

	getNames(opts) {
		return opts && opts.separator ? this.names.join(opts.separator) : this.names
	}

	getConfig() {
		return this.config
	}

	getTotalItems() {
		return this.totalItems
	}

	getItemTotals() {
		return this.itemTotals
	}

	isCompleted() {
		return this.completed
	}

	hasStarted() {
		return this.started
	}

	addGroup(...args) {
		return this.addTaskGroup(...args)
	}

	clear(...args) {
		this.clearRemaining(...args)
		return this
	}
}

// Exports
module.exports = { BaseInterface }
