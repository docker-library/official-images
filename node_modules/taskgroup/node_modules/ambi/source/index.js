'use strict'

// Import
const typeChecker = require('typechecker')

// Define
module.exports = function ambi(method, ...args) {
	// Extract the preceeding arguments and the completion callback
	const simpleArguments = args.slice(0, -1)
	const completionCallback = args.slice(-1)[0]

	// Check the completion callback is actually a function
	if (!typeChecker.isFunction(completionCallback)) {
		throw new Error('ambi was called without a completion callback')
	}

	/*
	Different ways functions can be called:
	ambi(function(a,next){return next()}, a, next)
		> VALID: execute asynchronously
		> given arguments are SAME as the accepted arguments
		> method will be fired with (a, next)
	ambi(function(a,next){return next()}, next)
		> VALID: execute asynchronously
		> given arguments are LESS than the accepted arguments
		> method will be fired with (undefined, next)
	ambi(function(a){}, a, next)
		> VALID: execute synchronously
		> given arguments are MORE than expected arguments
		> method will be fired with (a)
	ambi(function(a){}, next)
		> INVALID: execute asynchronously
		> given arguments are SAME as the accepted arguments
		> method will be fired with (next)
		> if they want to use optional args, the function must accept a completion callback
	*/
	const givenArgumentsLength = args.length
	// https://github.com/bevry/unbounded
	const acceptedArgumentsLength = (method.unbounded || method).length
	let argumentsDifferenceLength = null
	let executeAsynchronously = null

	// Given arguments are SAME as the expected arguments
	// This will execute asynchronously
	// Don't have to do anything with the arguments
	if (givenArgumentsLength === acceptedArgumentsLength) {
		executeAsynchronously = true
	}

	// Given arguments are LESS than the expected arguments
	// This will execute asynchronously
	// We will need to supplement any missing expected arguments with undefined
	// to ensure the compeltion callback is in the right place in the arguments listing
	else if (givenArgumentsLength < acceptedArgumentsLength) {
		executeAsynchronously = true
		argumentsDifferenceLength = acceptedArgumentsLength - givenArgumentsLength
		args = simpleArguments
			.slice()
			.concat(new Array(argumentsDifferenceLength))
			.concat([completionCallback])
	}

	// Given arguments are MORE than the expected arguments
	// This will execute synchronously
	// We should to trim off the completion callback from the arguments
	// as the synchronous function won't care for it
	// while this isn't essential
	// it will provide some expectation for the user as to which mode their function was executed in
	else {
		executeAsynchronously = false
		args = simpleArguments.slice()
	}

	// Execute with the exceptation that the method will fire the completion callback itself
	if (executeAsynchronously) {
		// Fire the method
		method(...args)
	}

	// Execute with the expectation that we will need to fire the completion callback ourselves
	// Always call the completion callback ourselves as the fire method does not make use of it
	else {
		// Fire the method and check for returned errors
		const result = method(...args)

		// Check the result for a returned error
		if (typeChecker.isError(result)) {
			// An error was returned so fire the completion callback with the error
			const err = result
			completionCallback(err)
		} else {
			// Everything worked, so fire the completion callback without an error and with the result
			completionCallback(null, result)
		}
	}

	// Return nothing as we expect ambi to deal with synchronous and asynchronous methods
	// so returning something will only work for synchronous methods
	// and not asynchronous ones
	// so returning anything would be inconsistent
	return null
}
