'use strict'

// Import
const typeChecker = require('typechecker')

/**
 * The options that are available to customise the behaviour of {@link custom}.
 * @typedef {object} Options
 * @property {boolean} [defaults=false] Only extend with a source value, if the target value is null or undefined.
 * @property {boolean} [traverse=false] If false, a shallow extend will be performed, if a true a deep/nested extend will be performed.
 */

/**
 * Extend target with the objects, with customisations.
 *
 * Target and sources can only be plain objects, any other type will throw, this is intentional to guarantee consistency of references.
 * Source values that are injected, will be dereferenced if they are plain objects or arrays.
 *
 * Plain Objects and Arrays will be dereferenced. All other types will keep their reference.
 *
 * @private
 * @param {Options} options
 * @param {object} target
 * @param  {...object} sources
 * @returns {object} target
 * @throws {Error} Throws in the case that the target or a source was not a plain object.
 */
function custom(options, target, ...sources) {
	const { defaults = false, traverse = false } = options
	if (!typeChecker.isPlainObject(target)) {
		throw new Error(
			'extendr only supports extending plain objects, target was not a plain object'
		)
	}
	for (let objIndex = 0; objIndex < sources.length; ++objIndex) {
		const obj = sources[objIndex]
		if (!typeChecker.isPlainObject(obj)) {
			throw new Error(
				'extendr only supports extending plain objects, an input was not a plain object'
			)
		}
		for (const key in obj) {
			if (obj.hasOwnProperty(key)) {
				// if not defaults only, always overwrite
				// if defaults only, overwrite if current value is empty
				const defaultSkip = defaults && target[key] != null

				// get the new value
				const newValue = obj[key]

				// ensure everything is new
				if (typeChecker.isPlainObject(newValue)) {
					if (traverse && typeChecker.isPlainObject(target[key])) {
						// replace current value with
						// dereferenced merged new object
						target[key] = custom(
							{ traverse, defaults },
							{},
							target[key],
							newValue
						)
					} else if (!defaultSkip) {
						// replace current value with
						// dereferenced new object
						target[key] = custom({ defaults }, {}, newValue)
					}
				} else if (!defaultSkip) {
					if (typeChecker.isArray(newValue)) {
						// replace current value with
						// dereferenced new array
						target[key] = newValue.slice()
					} else {
						// replace current value with
						// possibly referenced: function, class, etc
						// possibly unreferenced: string
						// new value
						target[key] = newValue
					}
				}
			}
		}
	}
	return target
}

/**
 * Shallow extend the properties from the sources into the target.
 * Performs {@link custom} with default options.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */
function extend(target, ...sources) {
	return custom({}, target, ...sources)
}

/**
 * Deep extend the properties from the sources into the target.
 * Performs {@link custom} with +traverse.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */
function deep(target, ...sources) {
	return custom({ traverse: true }, target, ...sources)
}

/**
 * Shallow extend the properties from the sources into the target, where the target's value is `undefined` or `null`.
 * Performs {@link custom} with +defaults.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */
function defaults(target, ...sources) {
	return custom({ defaults: true }, target, ...sources)
}

/**
 * Deep extend the properties from the sources into the target, where the target's value is `undefined` or `null`.
 * Performs {@link custom} with +traverse +defaults.
 * @param {object} target
 * @param {...object} sources
 * @returns {object} target
 */
function deepDefaults(target, ...sources) {
	return custom({ traverse: true, defaults: true }, target, ...sources)
}

/**
 * Deep extends the properties from the sources into a new object.
 * Performs {@link custom} with +traverse.
 * @param {...object} sources
 * @returns {object} target
 */
function clone(...sources) {
	return custom({ traverse: true }, {}, ...sources)
}

/**
 * Clones the object by stringifying it, then parsing the result, to ensure all references are destroyed.
 * Only serialisable values are kept, this means:
 * - Objects that are neither a Plain Object nor an Array will be lost.
 * - Class Instances, Functions and Regular Expressions will be discarded.
 * @param {object} source
 * @returns {object} dereferenced source
 */
function dereferenceJSON(source) {
	return JSON.parse(JSON.stringify(source))
}

/**
 * Clones the object by traversing through it and setting up new instances of anything that can be referenced.
 * Dereferences most things, including Regular Expressions.
 * Will not dereference functions and classes, they will throw.
 * @param {object} source
 * @returns {object} dereferenced source
 * @throws {Error} Throws in the case it encounters something it cannot dereference.
 */
function dereference(source) {
	if (typeChecker.isString(source)) {
		return source.toString()
	}

	if (typeChecker.isUndefined(source)) {
		return
	}

	if (typeChecker.isNull(source)) {
		return null
	}

	if (typeChecker.isNumber(source) || typeChecker.isBoolean(source)) {
		return dereferenceJSON(source)
	}

	if (typeChecker.isPlainObject(source)) {
		const result = {}
		for (const key in source) {
			if (source.hasOwnProperty(key)) {
				const value = source[key]
				result[key] = dereference(value)
			}
		}
		return result
	}

	if (typeChecker.isArray(source)) {
		return source.map(function(item) {
			return dereference(item)
		})
	}

	if (typeChecker.isDate(source)) {
		return new Date(source.toISOString())
	}

	if (typeChecker.isRegExp(source)) {
		if (source.flags == null) {
			throw new Error(
				'extendr cannot derefence RegExps on this older version of node'
			)
		} else {
			return new RegExp(source.source, source.flags)
		}
	}

	throw new Error(
		'extendr was passed an object type that it does not know how to derefence'
	)
}

// Export
module.exports = {
	custom,
	extend,
	deep,
	defaults,
	deepDefaults,
	clone,
	dereference,
	dereferenceJSON
}
