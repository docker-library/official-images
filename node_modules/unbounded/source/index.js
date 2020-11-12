'use strict'

const bind = Function.prototype.bind

function define(bounded, unbounded) {
	if (bounded.unbounded !== unbounded) {
		Object.defineProperty(bounded, 'unbounded', {
			value: unbounded.unbounded || unbounded,
			enumerable: false,
			configurable: false,
			writable: false
		})
	}
	return bounded
}

function binder(...args) {
	const bounded = bind.apply(this, args)
	define(bounded, this)
	return bounded
}

function patch() {
	if (Function.prototype.bind !== binder) {
		/* eslint no-extend-native:0 */
		Function.prototype.bind = binder
	}
	return module.exports
}

module.exports = { bind, binder, patch, define }
