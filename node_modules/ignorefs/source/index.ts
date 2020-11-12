// Import
import pathUtil from 'path'
import ignorePatterns from 'ignorepatterns'

interface IgnoreOpts {
	/** An optional listing of full paths to ignore */
	ignorePaths?: false | Array<string>
	/** Wether or not to ignore basenames beginning with a `.` character */
	ignoreHiddenFiles?: boolean
	/** If true, will check the path and basename of the path against https://github.com/bevry/ignorepatterns */
	ignoreCommonPatterns?: boolean | RegExp
	/** If a regular expression, will test the regular expression against the path and basename of the path */
	ignoreCustomPatterns?: false | RegExp
}

/**
 * Is Ignored Path
 * Check to see if a path, either a full path or basename, should be ignored
 * @param path A full path or basename of a file or directory
 * @param opts Configurations options
 * @returns Whether or not the path should be ignored
 */
export function isIgnoredPath(path: string, opts: IgnoreOpts = {}) {
	// Prepare
	const basename = pathUtil.basename(path)

	// Test Paths
	if (opts.ignorePaths) {
		for (let i = 0; i < opts.ignorePaths.length; ++i) {
			const ignorePath = opts.ignorePaths[i]
			if (path.indexOf(ignorePath) === 0) {
				return true
			}
		}
	}

	// Test Hidden Files
	if (opts.ignoreHiddenFiles && basename[0] === '.') {
		return true
	}

	// Test Common Patterns
	if (opts.ignoreCommonPatterns == null || opts.ignoreCommonPatterns === true) {
		return (
			ignorePatterns.test(path) ||
			(path !== basename && ignorePatterns.test(basename))
		)
	} else if (opts.ignoreCommonPatterns) {
		const ignoreCommonPatterns /* :RegExp */ = opts.ignoreCommonPatterns
		return (
			ignoreCommonPatterns.test(path) ||
			(path !== basename && ignoreCommonPatterns.test(basename))
		)
	}

	// Test Custom Patterns
	if (opts.ignoreCustomPatterns) {
		const ignoreCustomPatterns /* :RegExp */ = opts.ignoreCustomPatterns
		return (
			ignoreCustomPatterns.test(path) ||
			(path !== basename && ignoreCustomPatterns.test(basename))
		)
	}

	// Return
	return false
}
