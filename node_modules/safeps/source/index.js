/* eslint no-sync:0 */
'use strict'

// Import
const {TaskGroup} = require('taskgroup')
const typeChecker = require('typechecker')
const safefs = require('safefs')
const fsUtil = require('fs')
const pathUtil = require('path')
const extractOptsAndCallback = require('extract-opts')

// Prepare
const isWindows = (process.platform || '').indexOf('win') === 0
const DEFAULT_MAX_OPEN_PROCESSES = 100


// =====================================
// Define Globals

// Prepare
if ( global.safepsGlobal == null ) {
	global.safepsGlobal = {}
}

// Define Global Pool
// Create a pool with the concurrency of our max number of open processes
if ( global.safepsGlobal.pool == null ) {
	global.safepsGlobal.pool = new TaskGroup({
		concurrency: process.env.NODE_MAX_OPEN_PROCESSES == null ? DEFAULT_MAX_OPEN_PROCESSES : process.env.NODE_MAX_OPEN_PROCESSES,
		abortOnError: false,
		destroyOnceDone: false
	}).run()
}


// =====================================
// Define Module

/**
* Contains methods to safely spawn and manage
* various file system processes. It differs
* from the standard node.js child_process
* module in that it intercepts and handles
* many common errors that might occur when
* invoking child processes that could cause
* an application to crash. Most commonly, errors
* such as ENOENT and EACCESS. This enables
* an application to be both cleaner and more robust.
* @class safeps
* @static
*/
const safeps = {

	// =====================================
	// Open and Close Processes

	/**
	* Open a file.
	* Pass your callback to fire when it is safe to open the process
	* @param {Function} fn callback
	* @chainable
	* @return {this}
	*/
	openProcess (fn) {
		// Add the task to the pool and execute it right away
		global.safepsGlobal.pool.addTask(fn)

		// Chain
		return safeps
	},


	// =================================
	// Environments
	// @TODO These should be abstracted out into their own packages

	/**
	* Returns whether or not we are running on a windows machine
	* @return {Boolean}
	*/
	isWindows () {
		return isWindows
	},

	/**
	* Get locale code - eg: en-AU,
	* fr-FR, zh-CN etc.
	* @param {String} lang
	* @return {String}
	*/
	getLocaleCode (lang) {
		lang = lang || process.env.LANG || ''
		const localeCode = lang.replace(/\..+/, '').replace('-', '_').toLowerCase() || null
		return localeCode
	},

	/**
	* Given the localeCode, return
	* the language code.
	* @param {String} localeCode
	* @return {String}
	*/
	getLanguageCode (localeCode) {
		localeCode = safeps.getLocaleCode(localeCode) || ''
		const languageCode = localeCode.replace(/^([a-z]+)[_-]([a-z]+)$/i, '$1').toLowerCase() || null
		return languageCode
	},

	/**
	* Given the localeCode, return
	* the country code.
	* @param {String} localeCode
	* @return {String}
	*/
	getCountryCode (localeCode) {
		localeCode = safeps.getLocaleCode(localeCode) || ''
		const countryCode = localeCode.replace(/^([a-z]+)[_-]([a-z]+)$/i, '$2').toLowerCase() || null
		return countryCode
	},


	// =================================
	// Executeable Helpers

	/**
	* Has spawn sync. Returns true
	* if the child_process spawnSync
	* method exists, otherwise false
	* @return {Boolean}
	*/
	hasSpawnSync () {
		return require('child_process').spawnSync != null
	},

	/**
	* Has exec sync. Returns true
	* if the child_process execSync
	* method exists, otherwise false
	* @return {Boolean}
	*/
	hasExecSync () {
		return require('child_process').execSync != null
	},

	/**
	* Is the path to a file object an executable?
	* Synchronised version of isExecutable
	* @param {String} path path to test
	* @param {Object} opts
	* @param {Function} [next]
	* @param {Error} next.err
	* @param {Boolean} next.isExecutable
	* @return {Boolean}
	*/
	isExecutableSync (path, opts, next) {
		// Prepare
		let isExecutable

		// Access (Node 0.12+)
		if ( fsUtil.accessSync ) {
			try {
				fsUtil.accessSync(path, fsUtil.X_OK)
				isExecutable = true
			}
			catch ( err ) {
				isExecutable = false
			}
		}

		// Shim
		else {
			try {
				require('child_process').execSync(path + ' --version')
				isExecutable = true
			}
			catch ( err ) {
				// If there was an error
				// determine if it was an error with trying to run it (not executable)
				// or an error from running it (executable)
				isExecutable = err.code !== 127 && (/EACCESS|Permission denied/).test(err.message) === false
			}
		}

		// Return
		if ( next ) {
			next(null, isExecutable)
			return safeps
		}
		else {
			return isExecutable
		}
	},

	/**
	* Is the path to a file object an executable?
	* Boolean result returned as the isExecutable parameter
	* of the passed callback.
	* @param {String} path path to test
	* @param {Object} [opts]
	* @param {Boolean} [opts.sync] true to test sync rather than async
	* @param {Function} next callback
	* @param {Error} next.err
	* @param {Boolean} next.isExecutable
	* @return {Boolean} returned if opts.sync = true
	*/
	isExecutable (path, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// Sync?
		if ( opts.sync ) {
			return safeps.isExecutableSync(path, opts, next)
		}

		// Access (Node 0.12+)
		if ( fsUtil.access ) {
			fsUtil.access(path, fsUtil.X_OK, function (err) {
				const isExecutable = !err
				return next(null, isExecutable)
			})
		}

		// Shim
		else {
			require('child_process').exec(path + ' --version', function (err) {
				// If there was no error, then execution worked fine, so we are executable
				if ( !err )  return next(null, true)
				// If there was an error
				// determine if it was an error with trying to run it (not executable)
				// or an error from running it (executable)
				const isExecutable = err.code !== 127 && (/EACCESS|Permission denied/).test(err.message) === false
				return next(null, isExecutable)
			})
		}

		// Chain
		return safeps
	},

	/**
	* Internal: Prepare options for an execution.
	* Makes sure all options are populated or exist and
	* gives the opportunity to prepopulate some of those
	* options.
	* @access private
	* @param {Object} [opts]
	* @param {Stream} [opts.stdin=null] in stream
	* @param {Array} [opts.stdio=null] Child's stdio configuration
	* @param {Boolean} [opts.safe=true]
	* @param {Object} [opts.env=process.env]
	* @return {Object} opts
	*/
	prepareExecutableOptions (opts) {
		// Prepare
		opts = opts || {}

		// Ensure all options exist
		if ( typeof opts.stdin === 'undefined' )  opts.stdin = null
		if ( typeof opts.stdio === 'undefined' )  opts.stdio = null

		// By default make sure execution is valid
		if ( opts.safe == null )   opts.safe = true

		// If a direct pipe then don't do output modifiers
		if ( opts.stdio ) {
			opts.read = opts.output = false
			opts.outputPrefix = null
		}

		// Otherwise, set output modifiers
		else {
			if ( opts.read == null )          opts.read = true
			if ( opts.output == null )        opts.output = Boolean(opts.outputPrefix)
			if ( opts.outputPrefix == null )  opts.outputPrefix = null
		}

		// By default inherit environment variables
		if ( opts.env == null ) {
			opts.env = process.env
		}
		// If we don't want to inherit environment variables, then don't
		else if ( opts.env === false ) {
			opts.env = null
		}

		// Return
		return opts
	},

	/**
	* Internal: Prepare result of an execution
	* @access private
	* @param {Object} result
	* @param {Object} result.pid  Number Pid of the child process
	* @param {Object} result.output output Array Array of results from stdio output
	* @param {Stream} result.stdout stdout The contents of output
	* @param {Stream} result.stderr stderr The contents of output
	* @param {Number} result.status status The exit code of the child process
	* @param {String} result.signal signal The signal used to kill the child process
	* @param {Error} result.error The error object if the child process failed or timed out
	* @param {Object} [opts]
	* @param {Object} [opts.output]
	* @param {Object} [opts.outputPrefix]
	* @return {Object} result
	*/
	updateExecutableResult (result, opts) {
		// If we want to output, then output the correct streams with the correct prefixes
		if ( opts.output ) {
			safeps.outputData(result.stdout, 'stdout', opts.outputPrefix)
			safeps.outputData(result.stderr, 'stderr', opts.outputPrefix)
		}

		// If we already have an error, then don't continue
		if ( result.error ) {
			return result
		}

		// We don't already have an error, so let's check the status code for an error
		// Check if the status code exists, and if it is not zero, zero is the success code
		if ( result.status != null && result.status !== 0 ) {
			let message = 'Command exited with a non-zero status code.'

			// As there won't be that much information on this error, as it was not already provided
			// we should output the stdout if we have it
			if ( result.stdout ) {
				const tmp = safeps.prefixData(result.stdout)
				if ( tmp ) {
					message += "\nThe command's stdout output:\n" + tmp
				}
			}
			// and output the stderr if we have it
			if ( result.stderr ) {
				const tmp = safeps.prefixData(result.stderr)
				if ( tmp ) {
					message += "\nThe command's stderr output:\n" + tmp
				}
			}

			// and create the error from that output
			result.error = new Error(message)
			return result
		}

		// Success
		return result
	},


	/**
	* Internal: prefix data
	* @access private
	* @param {Object} data
	* @param {String} [prefix = '>\t']
	* @return {Object} data
	*/
	prefixData (data, prefix = '>\t') {
		data = (data && data.toString && data.toString()) || ''
		if ( prefix && data ) {
			data = prefix + data.trim().replace(/\n/g, '\n' + prefix) + '\n'
		}
		return data
	},

	/**
	* Internal: Set output data
	* @access private
	* @param {Object} data
	* @param {Object} [channel = 'stdout']
	* @param {Object} prefix
	* @chainable
	* @return {this}
	*/
	outputData (data, channel = 'stdout', prefix) {
		if ( data.toString().trim().length !== 0 ) {
			if ( prefix ) {
				data = safeps.prefixData(data, prefix)
			}
			process[channel].write(data)
		}
		return null
	},


	// =================================
	// Spawn

	/**
	* Syncronised version of safeps.spawn. Will not return until the
	* child process has fully closed. Results can be returned
	* from the method call or via a passed callback. Even if
	* a callback is passed to spawnSync, the method will still
	* be syncronised with the child process and the callback will
	* only return after the child process has closed.
	*
	* Simple usage example:
	*
	*	var safeps = require('safeps');
	*	var command = ['npm', 'install', 'jade', '--save'];
	*
	*	//a lot of the time you won't need the opts argument
	*	var opts = {
	*		cwd: __dirname //this is actually pointless in a real application
	*	};
	*
	*	var result = safeps.spawnSync(command, opts);
	*
	*	console.log(result.error);
	*	console.log(result.status);
	*	console.log(result.signal);
	*	console.log("I've finished...");
	*
	* @param {Array|String} command
	* @param {Object} [opts]
	* @param {Boolean} [opts.safe] Whether to check the executable path.
	* @param {String} [opts.cwd] Current working directory of the child process
	* @param {Array|String} [opts.stdio] Child's stdio configuration.
	* @param {Array} [opts.customFds] Deprecated File descriptors for the child to use for stdio.
	* @param {Object} [opts.env] Environment key-value pairs.
	* @param {Boolean} [opts.detached] The child will be a process group leader.
	* @param {Number} [opts.uid] Sets the user identity of the process.
	* @param {Number} [opts.gid] Sets the group identity of the process
	* @param {Function} [next] callback
	* @param {Error} next.error
	* @param {Stream} next.stdout out stream
	* @param {Stream} next.stderr error stream
	* @param {Number} next.status node.js exit code
	* @param {String} next.signal unix style signal such as SIGKILL or SIGHUP
	* @return {Object} {error, pid, output, stdout, stderr, status, signal}
	*/
	spawnSync (command, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		opts = safeps.prepareExecutableOptions(opts)
		opts.sync = true

		// If the command is a string, then convert it into an array
		if ( typeChecker.isString(command) ) {
			command = command.split(' ')
		}

		// Get correct executable path
		// Only possible if sync abilities are possible (node 0.12 and up) or if it is cached
		// Otherwise, don't worry about it and output a warning to stderr
		if ( opts.safe ) {
			let wasSync = 0
			safeps.getExecPath(command[0], opts, function (err, execPath) {
				if ( err )  return
				command[0] = execPath
				wasSync = 1
			})
			if ( wasSync === 0 ) {
				process.stderr.write('safeps.spawnSync: was unable to get the executable path synchronously')
			}
		}

		// Spawn Synchronously
		const result = require('child_process').spawnSync(command[0], command.slice(1), opts)
		safeps.updateExecutableResult(result, opts)

		// Complete
		if ( next ) {
			next(result.error, result.stdout, result.stderr, result.status, result.signal)
		}
		else {
			return result
		}
	},

	/**
	* Wrapper around node's spawn command for a cleaner, more robust and powerful API.
	* Launches a new process with the given command. Command line arguments are
	* part of the command parameter (unlike the node.js spawn). Command can be
	* an array of command line arguments or a command line string. Opts allows
	* additional options to be sent to the spawning action.
	*
	* Simple usage example:
	*
	* 	var safeps = require('safeps');
	*	var command = ['npm', 'install','jade','--save'];
	*
	*	//a lot of the time you won't need the opts argument
	*	var opts = {
	*		cwd: __dirname //this is actually pointless in a real application
	*	}
	*	function myCallback(error, stdout, stderr, status, signal){
	*		console.log(error);
	*		console.log(status);
	*		console.log(signal);
	*		console.log("I've finished...");
	*	}
	*	safeps.spawn(command, opts, myCallback);
	*
	* @param {Array|String} command
	* @param {Object} [opts]
	* @param {Boolean} [opts.safe] Whether to check the executable path.
	* @param {String} [opts.cwd] Current working directory of the child process
	* @param {Array|String} [opts.stdio] Child's stdio configuration.
	* @param {Array} [opts.customFds] Deprecated File descriptors for the child to use for stdio.
	* @param {Object} [opts.env] Environment key-value pairs.
	* @param {Boolean} [opts.detached] The child will be a process group leader.
	* @param {Number} [opts.uid] Sets the user identity of the process.
	* @param {Number} [opts.gid] Sets the group identity of the process.
	* @param {Function} next callback
	* @param {Error} next.error
	* @param {Stream} next.stdout out stream
	* @param {Stream} next.stderr error stream
	* @param {Number} next.status node.js exit code
	* @param {String} next.signal unix style signal such as SIGKILL or SIGHUP
	* @chainable
	* @return {this}
	*/
	spawn (command, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		opts = safeps.prepareExecutableOptions(opts)

		// Check if we want sync instead
		if ( opts.sync ) {
			return safeps.spawnSync(command, opts, next)
		}

		// Patience
		safeps.openProcess(function (closeProcess) {
			// If the command is a string, then convert it into an array
			if ( typeChecker.isString(command) ) {
				command = command.split(' ')
			}

			// Prepare
			const result = {
				pid: null,
				stdout: null,
				stderr: null,
				output: null,
				error: null,
				status: null,
				signal: null
			}
			let exited = false

			// Tasks
			const tasks = new TaskGroup().done(function (err) {
				exited = true
				closeProcess()
				next(err || result.error, result.stdout, result.stderr, result.status, result.signal)
			})

			// Get correct executable path
			if ( opts.safe ) {
				tasks.addTask(function (complete) {
					safeps.getExecPath(command[0], opts, function (err, execPath) {
						if ( err )  return complete(err)
						command[0] = execPath
						complete()
					})
				})
			}

			// Spawn
			tasks.addTask(function (complete) {
				// Spawn
				result.pid = require('child_process').spawn(command[0], command.slice(1), opts)

				// Write if we want to
				// result.pid.stdin may be null of stdio is 'inherit'
				if ( opts.stdin && result.pid.stdin) {
					result.pid.stdin.write(opts.stdin)
					result.pid.stdin.end()
				}

				// Read if we want to by listening to the streams and updating our result variables
				if ( opts.read ) {
					// result.pid.stdout may be null of stdio is 'inherit'
					if ( result.pid.stdout ) {
						result.pid.stdout.on('data', function (data) {
							if ( opts.output ) {
								safeps.outputData(data, 'stdout', opts.outputPrefix)
							}
							if ( result.stdout ) {
								result.stdout = Buffer.concat([result.stdout, data])
							}
							else {
								result.stdout = data
							}
						})
					}

					// result.pid.stderr may be null of stdio is 'inherit'
					if ( result.pid.stderr ) {
						result.pid.stderr.on('data', function (data) {
							if ( opts.output) {
								safeps.outputData(data, 'stderr', opts.outputPrefix)
							}
							if ( result.stderr ) {
								result.stderr = Buffer.concat([result.stderr, data])
							}
							else {
								result.stderr = data
							}
						})
					}
				}

				// Wait
				result.pid.on('close', function (status, signal) {
					// Apply to local global
					result.status = status
					result.signal = signal

					// Check if we have already exited due to domains
					// as without this, then we will fire the completion callback twice
					// once for the domain error that will happen first
					// then again for the close error
					// if it happens the other way round, close, then error, we want to be alerted of that
					if ( exited === true )  return

					// Check result and complete
					opts.output = false
					safeps.updateExecutableResult(result, opts)
					return complete(result.error)
				})
			})

			// Run
			tasks.run()
		})

		// Chain
		return safeps
	},

	/**
	* Spawn multiple processes in the one method call.
 	* Launches new processes with the given array of commands.
	* Each item in the commands array represents a command parameter
	* sent to the safeps.spawn method, so each item can be a command line
	* string or an array of command line inputs. It is also possible
	* to pass a single command string and in this case calling
	* spawnMultiple will be effectively the same as calling safeps.spawn.
	* @param {Array|String} commands
	* @param {Object} [opts]
	* @param {Boolean} [opts.concurrency=1] Whether to spawn processes concurrently.
	* @param {String} opts.cwd Current working directory of the child process.
	* @param {Array|String} opts.stdio Child's stdio configuration.
	* @param {Array} opts.customFds Deprecated File descriptors for the child to use for stdio.
	* @param {Object} opts.env Environment key-value pairs.
	* @param {Boolean} opts.detached The child will be a process group leader.
	* @param {Number} opts.uid Sets the user identity of the process.
	* @param {Number} opts.gid Sets the group identity of the process.
	* @param {Function} next callback
	* @param {Error} next.error
	* @param {Array} next.results array of spawn results
	* @param {Stream} next.results[i].stdout out stream
	* @param {Stream} next.results[i].stderr error stream
	* @param {Number} next.results[i].status node.js exit code
	* @param {String} next.results[i].signal unix style signal such as SIGKILL or SIGHUP
	* @chainable
	* @return {this}
	*/
	spawnMultiple (commands, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		const results = []

		// Be synchronous by default
		if ( opts.concurrency == null )  opts.concurrency = 1

		// Make sure we send back the arguments
		const tasks = new TaskGroup({concurrency: opts.concurrency}).done(function (err) {
			next(err, results)
		})

		// Prepare tasks
		if ( !typeChecker.isArray(commands) ) {
			commands = [commands]
		}

		// Add tasks
		commands.forEach(function (command) {
			tasks.addTask(function (complete) {
				safeps.spawn(command, opts, function (...args) {
					const err = args[0] || null
					results.push(args)
					complete(err)
				})
			})
		})

		// Run the tasks
		tasks.run()

		// Chain
		return safeps
	},


	// =================================
	// Exec

	/**
	* Syncronised version of safeps.exec. Runs a command in a shell and
	* buffers the output. Will not return until the
	* child process has fully closed. Results can be returned
	* from the method call or via a passed callback. Even if
	* a callback is passed to execSync, the method will still
	* be syncronised with the child process and the callback will
	* only return after the child process has closed.
	* Note:
	* Stdout and stderr should be Buffers but they are strings unless encoding:null
	* for now, nothing we should do, besides wait for joyent to reply
	* https://github.com/joyent/node/issues/5833#issuecomment-82189525.
	* @param {Object} command
	* @param {Object} [opts]
	* @param {Boolean} [opts.sync] true to execute sync rather than async
	* @param {String} [opts.cwd] Current working directory of the child process
	* @param {Object} [opts.env] Environment key-value pairs
	* @param {String} [opts.encoding='utf8']
	* @param {String} [opts.shell] Shell to execute the command with (Default: '/bin/sh' on UNIX, 'cmd.exe' on Windows, The shell should understand the -c switch on UNIX or /s /c on Windows. On Windows, command line parsing should be compatible with cmd.exe.)
	* @param {Number} [opts.timeout=0]
	* @param {Number} [opts.maxBuffer=200*1024] Largest amount of data (in bytes) allowed on stdout or stderr - if exceeded child process is killed.
	* @param {String} [opts.killSignal='SIGTERM']
	* @param {Number} [opts.uid] Sets the user identity of the process.
	* @param {Number} [opts.gid] Sets the group identity of the process.
	* @param {Function} next
	* @param {Error} next.err
	* @param {Buffer|String} next.stdout out buffer
	* @param {Buffer|String} next.stderr error buffer
	* @return {Object} {error, stdout, stderr}
	*/
	execSync (command, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		opts = safeps.prepareExecutableOptions(opts)
		opts.sync = true

		// Output
		if ( opts.output === true && !opts.outputPrefix ) {
			opts.stdio = 'inherit'
			opts.output = null
		}

		// Spawn Synchronously
		let stdout, error
		try {
			stdout = require('child_process').execSync(command, opts)
		}
		catch ( err ) {
			error = err
		}

		// Check result
		const result = {error, stdout}
		safeps.updateExecutableResult(result, opts)

		// Complete
		if ( next ) {
			next(result.error, result.stdout, result.stderr)
		}
		else {
			return result
		}
	},

	/**
	* Wrapper around node's exec command for a cleaner, more robust and powerful API.
	* Runs a command in a shell and buffers the output.
	* Note:
	* Stdout and stderr should be Buffers but they are strings unless encoding:null
	* for now, nothing we should do, besides wait for joyent to reply
	* https://github.com/joyent/node/issues/5833#issuecomment-82189525.
	* @param {Object} command
	* @param {Object} [opts]
	* @param {Boolean} [opts.sync] true to execute sync rather than async
	* @param {String} [opts.cwd] Current working directory of the child process
	* @param {Object} [opts.env] Environment key-value pairs
	* @param {String} [opts.encoding='utf8']
	* @param {String} [opts.shell] Shell to execute the command with (Default: '/bin/sh' on UNIX, 'cmd.exe' on Windows, The shell should understand the -c switch on UNIX or /s /c on Windows. On Windows, command line parsing should be compatible with cmd.exe.)
	* @param {Number} [opts.timeout=0]
	* @param {Number} [opts.maxBuffer=200*1024] Largest amount of data (in bytes) allowed on stdout or stderr - if exceeded child process is killed.
	* @param {String} [opts.killSignal='SIGTERM']
	* @param {Number} [opts.uid] Sets the user identity of the process.
	* @param {Number} [opts.gid] Sets the group identity of the process.
	* @param {Function} next
	* @param {Error} next.err
	* @param {Buffer|String} next.stdout out buffer
	* @param {Buffer|String} next.stderr error buffer
	* @chainable
	* @return {this}
	*/
	exec (command, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		opts = safeps.prepareExecutableOptions(opts)

		// Check if we want sync instead
		if ( opts.sync ) {
			return safeps.execSync(command, opts, next)
		}

		// Patience
		safeps.openProcess(function (closeProcess) {
			// Output
			if ( opts.output === true && !opts.outputPrefix ) {
				opts.stdio = 'inherit'
				opts.output = null
			}

			// Execute command
			require('child_process').exec(command, opts, function (error, stdout, stderr) {
				// Complete the task
				closeProcess()

				// Prepare result
				const result = {error, stdout, stderr}
				safeps.updateExecutableResult(result, opts)

				// Complete
				return next(result.error, result.stdout, result.stderr)
			})
		})

		// Chain
		return safeps
	},

	/**
	* Exec multiple processes in the one method call.
 	* Launches new processes with the given array of commands.
	* Each item in the commands array represents a command parameter
	* sent to the safeps.exec method, so each item can be a command line
	* string or an array of command line inputs. It is also possible
	* to pass a single command string and in this case calling
	* execMultiple will be effectively the same as calling safeps.exec.
	* @param {Array|String} commands
	* @param {Object} [opts]
	* @param {Boolean} [opts.concurrency=1] Whether to exec processes concurrently.
	* @param {String} opts.cwd Current working directory of the child process.
	* @param {Array|String} opts.stdio Child's stdio configuration.
	* @param {Array} opts.customFds Deprecated File descriptors for the child to use for stdio.
	* @param {Object} opts.env Environment key-value pairs.
	* @param {Boolean} opts.detached The child will be a process group leader.
	* @param {Number} opts.uid Sets the user identity of the process.
	* @param {Number} opts.gid Sets the group identity of the process.
	* @param {Function} next callback
	* @param {Error} next.error
	* @param {Array} next.results array of exec results
	* @param {Stream} next.results[i].stdout out buffer
	* @param {Stream} next.results[i].stderr error buffer
	* @chainable
	* @return {this}
	*/
	execMultiple (commands, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		const results = []

		// Be synchronous by default
		if ( opts.concurrency == null )  opts.concurrency = 1

		// Make sure we send back the arguments
		const tasks = new TaskGroup({concurrency: opts.concurrency}).done(function (err) {
			next(err, results)
		})

		// Prepare tasks
		if ( !typeChecker.isArray(commands) ) {
			commands = [commands]
		}

		// Add tasks
		commands.forEach(function (command) {
			tasks.addTask(function (complete) {
				safeps.exec(command, opts, function (...args) {
					const err = args[0] || null
					results.push(args)
					complete(err)
				})
			})
		})

		// Run the tasks
		tasks.run()

		// Chain
		return safeps
	},


	// =================================
	// Paths

	/**
	* Determine an executable path from the passed array of possible file paths.
	* Called by getExecPath to find a path for a given executable name.
	* @access private
	* @param {Array} possibleExecPaths string array of file paths
	* @param {Object} [opts]
	* @param {Boolean} [opts.sync] true to execute sync rather than async
	* @param {Function} [next]
	* @param {Error} next.err
	* @param {String} next.execPath
	* @chainable
	* @return {this}
	*/
	determineExecPathSync (possibleExecPaths, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		let execPath = null

		// Handle
		possibleExecPaths.forEach(function (possibleExecPath) {
			// Check if we have found the valid exec path earlier, if so, skip
			// Check if the path is invalid, if it is, skip it
			if ( execPath || !possibleExecPath )  return

			// Resolve the path as it may be a virtual or relative path
			possibleExecPath = pathUtil.resolve(possibleExecPath)

			// Check if the executeable exists
			safeps.isExecutableSync(possibleExecPath, opts, function (err, isExecutable) {
				if ( !err && isExecutable )  execPath = possibleExecPath
			})
		})

		// Return
		if ( next ) {
			next(null, execPath)
			return safeps
		}
		else {
			return execPath
		}
	},

	/**
	* Determine an executable path from
	* the passed array of possible file paths.
	* Called by getExecPath to find a path for
	* a given executable name.
	* @access private
	* @param {Array} possibleExecPaths string array of file paths
	* @param {Object} [opts]
	* @param {Boolean} [opts.sync] true to execute sync rather than async
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.execPath
	* @chainable
	* @return {this}
	*/
	determineExecPath (possibleExecPaths, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)
		let execPath = null

		// Sync?
		if ( opts.sync ) {
			return safeps.determineExecPathSync(possibleExecPaths, opts, next)
		}

		// Group
		const tasks = new TaskGroup().done(function (err) {
			return next(err, execPath)
		})

		// Handle
		possibleExecPaths.forEach(function (possibleExecPath) {
			// Check if the path is invalid, if it is, skip it
			if ( !possibleExecPath )  return
			tasks.addTask(function (complete) {
				// Check if we have found the valid exec path earlier, if so, skip
				if ( execPath )  return complete()

				// Resolve the path as it may be a virtual or relative path
				possibleExecPath = pathUtil.resolve(possibleExecPath)

				// Check if the executeable exists
				safeps.isExecutable(possibleExecPath, opts, function (err, isExecutable) {
					if ( !err && isExecutable )  execPath = possibleExecPath
					return complete()
				})
			})
		})

		// Fire the tasks
		tasks.run()

		// Chain
		return safeps
	},

	/**
	* Get the system's environment paths.
	* @return {Array} string array of file paths
	*/
	getEnvironmentPaths () {
		// Fetch system include paths with the correct delimiter for the system
		const environmentPaths = process.env.PATH.split(pathUtil.delimiter)

		// Return
		return environmentPaths
	},

	/**
	* Get the possible paths for
	* the passed executable using the
	* standard environment paths. Basically,
	* get a list of places to look for the
	* executable. Only safe for non-Windows
	* systems.
	* @access private
	* @param {String} execName
	* @return {Array} string array of file paths
	*/
	getStandardExecPaths (execName) {
		// Fetch
		let standardExecPaths = [process.cwd()].concat(safeps.getEnvironmentPaths())

		// Get the possible exec paths
		if ( execName ) {
			standardExecPaths = standardExecPaths.map(function (path) {
				return pathUtil.join(path, execName)
			})
		}

		// Return
		return standardExecPaths
	},

	/**
	* Get the possible paths for
	* the passed executable using the
	* standard environment paths. Basically,
	* get a list of places to look for the
	* executable. Makes allowances for Windows
	* executables possibly needing an extension
	* to ensure execution (.exe, .cmd, .bat).
	* @access private
	* @param {String} execName
	* @return {Array} string array of file paths
	*/
	getPossibleExecPaths (execName) {
		let possibleExecPaths

		// Fetch available paths
		if ( isWindows && execName.indexOf('.') === -1 ) {
			// we are for windows add the paths for .exe as well
			const standardExecPaths = safeps.getStandardExecPaths(execName)
			possibleExecPaths = []
			for ( let i = 0; i < standardExecPaths.length; ++i ) {
				const standardExecPath = standardExecPaths[i]
				possibleExecPaths.push(
					standardExecPath,
					standardExecPath + '.exe',
					standardExecPath + '.cmd',
					standardExecPath + '.bat'
				)
			}
		}
		else {
			// we are normal, try the paths
			possibleExecPaths = safeps.getStandardExecPaths(execName)
		}

		// Return
		return possibleExecPaths
	},

	/**
	* Cache of executable paths
	* @access private
	* @property execPathCache
	*/
	execPathCache: {},

	/**
	* Given an executable name, search and find
	* its actual path. Will search the standard
	* file paths defined by the environment to
	* see if the executable is in any of those paths.
	* @param {Object} execName
	* @param {Object} [opts]
	* @param {Boolean} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.foundPath path to the executable
	* @chainable
	* @return {this}
	*/
	getExecPath (execName, opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Check for absolute path, as we would not be needed and would just currupt the output
		if ( execName.substr(0, 1) === '/' || execName.substr(1, 1) === ':' ) {
			next(null, execName)
			return safeps
		}

		// Prepare
		const execNameCapitalized = execName[0].toUpperCase() + execName.substr(1)
		const getExecMethodName = `get${execNameCapitalized}Path`

		// Check for special case
		if ( safeps[getExecMethodName] ) {
			return safeps[getExecMethodName](opts, next)
		}
		else {
			// Check for cache
			if ( opts.cache && safeps.execPathCache[execName] ) {
				next(null, safeps.execPathCache[execName])
				return safeps
			}

			// Fetch possible exec paths
			const possibleExecPaths = safeps.getPossibleExecPaths(execName)

			// Forward onto determineExecPath
			// Which will determine which path it is out of the possible paths
			safeps.determineExecPath(possibleExecPaths, opts, function (err, execPath) {
				if ( err ) {
					next(err)
				}
				else if ( !execPath ) {
					err = new Error(`Could not locate the ${execName} executable path`)
					next(err)
				}
				else {
					// Success, write the result to cache and send to our callback
					if ( opts.cache )  safeps.execPathCache[execName] = execPath
					return next(null, execPath)
				}
			})
		}

		// Chain
		return safeps
	},

	/**
	* Get home path. Returns the user's home directory.
	* Based upon home function from: https://github.com/isaacs/osenv
	* @param {Object} [opts]
	* @param {Object} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.homePath
	* @chainable
	* @return {this}
	*/
	getHomePath (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Cached
		if ( opts.cache && safeps.cachedHomePath ) {
			next(null, safeps.cachedHomePath)
			return safeps
		}

		// Fetch
		const homePath = process.env.USERPROFILE || process.env.HOME || null

		// Success, write the result to cache and send to our callback
		if ( opts.cache )  safeps.cachedHomePath = homePath
		next(null, homePath)

		// Chain
		return safeps
	},

	/**
	* Path to the evironment's temporary directory.
	* Based upon tmpdir function from: https://github.com/isaacs/osenv
	* @param {Object} [opts]
	* @param {Object} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.tmpPath
	* @chainable
	* @return {this}
	*/
	getTmpPath (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Cached
		if ( opts.cache && safeps.cachedTmpPath ) {
			next(null, safeps.cachedTmpPath)
			return safeps
		}

		// Prepare
		const tmpDirName = isWindows ? 'temp' : 'tmp'

		// Try the OS environment temp path
		let tmpPath = process.env.TMPDIR || process.env.TMP || process.env.TEMP || null

		// Fallback
		if ( !tmpPath ) {
			// Try the user directory temp path
			safeps.getHomePath(opts, function (err, homePath) {
				if ( err )  return next(err)
				tmpPath = pathUtil.resolve(homePath, tmpDirName)

				// Fallback
				if ( !tmpPath ) {
					// Try the system temp path
					// @TODO perhaps we should check if we have write access to this path
					tmpPath = isWindows
						? pathUtil.resolve(process.env.windir || 'C:\\Windows', tmpDirName)
						: '/tmp'
				}
			})
		}

		// Check if we couldn't find it, we should always be able to find it
		if ( !tmpPath ) {
			const err = new Error("Wan't able to find a temporary path")
			next(err)
		}

		// Success, write the result to cache and send to our callback
		if ( opts.cache )  safeps.cachedTmpPath = tmpPath
		next(null, tmpPath)

		// Chain
		return safeps
	},

	/**
	* Path to the evironment's GIT directory.
	* As 'git' is not always available in the environment path, we should check
	* common path locations and if we find one that works, then we should use it.
	* @param {Object} [opts]
	* @param {Object} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.gitPath
	* @chainable
	* @return {this}
	*/
	getGitPath (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Cached
		if ( opts.cache && safeps.cachedGitPath ) {
			next(null, safeps.cachedGitPath)
			return safeps
		}

		// Prepare
		const execName = isWindows ? 'git.exe' : 'git'
		const possibleExecPaths = []

		// Add environment paths
		if ( process.env.GIT_PATH )  possibleExecPaths.push(process.env.GIT_PATH)
		if ( process.env.GITPATH  )  possibleExecPaths.push(process.env.GITPATH)

		// Add standard paths
		possibleExecPaths.push(...safeps.getStandardExecPaths(execName))

		// Add custom paths
		if ( isWindows ) {
			possibleExecPaths.push(
				`/Program Files (x64)/Git/bin/${execName}`,
				`/Program Files (x86)/Git/bin/${execName}`,
				`/Program Files/Git/bin/${execName}`
			)
		}
		else {
			possibleExecPaths.push(
				`/usr/local/bin/${execName}`,
				`/usr/bin/${execName}`,
				`~/bin/${execName}`
			)
		}

		// Determine the right path
		safeps.determineExecPath(possibleExecPaths, opts, function (err, execPath) {
			if ( err ) {
				next(err)
			}
			else if ( !execPath ) {
				err = new Error('Could not locate git binary')
				next(err)
			}
			else {
				// Success, write the result to cache and send to our callback
				if ( opts.cache )  safeps.cachedGitPath = execPath
				next(null, execPath)
			}
		})

		// Chain
		return safeps
	},

	/**
	* Path to the evironment's Node directory.
	* As 'node' is not always available in the environment path, we should check
	* common path locations and if we find one that works, then we should use it
	* @param {Object} [opts]
	* @param {Object} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.nodePath
	* @chainable
	* @return {this}
	*/
	getNodePath (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Cached
		if ( opts.cache && safeps.cachedNodePath ) {
			next(null, safeps.cachedNodePath)
			return safeps
		}

		// Prepare
		const execName = isWindows ? 'node.exe' : 'node'
		const possibleExecPaths = []

		// Add environment paths
		if ( process.env.NODE_PATH )                  possibleExecPaths.push(process.env.NODE_PATH)
		if ( process.env.NODEPATH )                   possibleExecPaths.push(process.env.NODEPATH)
		if ( /node(.exe)?$/.test(process.execPath) )  possibleExecPaths.push(process.execPath)

		// Add standard paths
		possibleExecPaths.push(...safeps.getStandardExecPaths(execName))

		// Add custom paths
		if ( isWindows ) {
			possibleExecPaths.push(
				`/Program Files (x64)/nodejs/${execName}`,
				`/Program Files (x86)/nodejs/${execName}`,
				`/Program Files/nodejs/${execName}`
			)
		}
		else {
			possibleExecPaths.push(
				`/usr/local/bin/${execName}`,
				`/usr/bin/${execName}`,
				`~/bin/${execName}`  // User and Heroku
			)
		}

		// Determine the right path
		safeps.determineExecPath(possibleExecPaths, opts, function (err, execPath) {
			if ( err ) {
				next(err)
			}
			else if ( !execPath ) {
				err = new Error('Could not locate node binary')
				next(err)
			}
			else {
				// Success, write the result to cache and send to our callback
				if ( opts.cache )  safeps.cachedNodePath = execPath
				next(null, execPath)
			}
		})

		// Chain
		return safeps
	},

	/**
	* Path to the evironment's NPM directory.
	* As 'npm' is not always available in the environment path, we should check
	* common path locations and if we find one that works, then we should use it
	* @param {Object} [opts]
	* @param {Object} [opts.cache=true]
	* @param {Function} next
	* @param {Error} next.err
	* @param {String} next.npmPath
	* @chainable
	* @return {this}
	*/
	getNpmPath (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// By default read from the cache and write to the cache
		if ( opts.cache == null )  opts.cache = true

		// Cached
		if ( opts.cache && safeps.cachedNpmPath ) {
			next(null, safeps.cachedNpmPath)
			return safeps
		}

		// Prepare
		const execName = isWindows ? 'npm.cmd' : 'npm'
		const possibleExecPaths = []

		// Add environment paths
		if ( process.env.NPM_PATH )                   possibleExecPaths.push(process.env.NPM_PATH)
		if ( process.env.NPMPATH )                    possibleExecPaths.push(process.env.NPMPATH)
		if ( /node(.exe)?$/.test(process.execPath) )  possibleExecPaths.push(process.execPath.replace(/node(.exe)?$/, execName))

		// Add standard paths
		possibleExecPaths.push(...safeps.getStandardExecPaths(execName))

		// Add custom paths
		if ( isWindows ) {
			possibleExecPaths.push(
				`/Program Files (x64)/nodejs/${execName}`,
				`/Program Files (x86)/nodejs/${execName}`,
				`/Program Files/nodejs/${execName}`
			)
		}
		else {
			possibleExecPaths.push(
				`/usr/local/bin/${execName}`,
				`/usr/bin/${execName}`,
				`~/node_modules/.bin/${execName}` // User and Heroku
			)
		}

		// Determine the right path
		safeps.determineExecPath(possibleExecPaths, opts, function (err, execPath) {
			if ( err ) {
				next(err)
			}
			else if ( !execPath ) {
				err = new Error('Could not locate npm binary')
				next(err)
			}
			else {
				// Success, write the result to cache and send to our callback
				if ( opts.cache )  safeps.cachedNpmPath = execPath
				next(null, execPath)
			}
		})

		// Chain
		return safeps
	},


	// =================================
	// Special Commands
	// @TODO These should be abstracted out into their own packages

	/**
	* Initialize a git repository, including submodules, and will prepare the given options if they are provided.
	* @param {Object} opts also forwarded to {@link spawnMultiple}
	* @param {String} [opts.cwd=process.cwd()] path to initiate the repository, can also be `opts.path`
	* @param {String} [opts.url] the remote url, e.g. `https://github.com/bevry/safeps.git`
	* @param {String} [opts.remote] the remote name, e.g. `origin`
	* @param {String} [opts.branch] the branch to use, e.g. `master`
	* @param {Function} next
	* @param {Error} next.err
	* @chainable
	* @return {this}
	*/
	initGitRepo (opts, next) {
		// Extract
		[opts, next] = extractOptsAndCallback(opts, next)

		// Defaults
		if (opts.path) {
			opts.cwd = opts.path
			delete opts.path
		}
		if (!opts.cwd) {
			opts.cwd = process.cwd()
		}

		// Prepare
		function partTwo (err) {
			if (err) return next(err)
			const commands = []
			if (opts.remote) {
				commands.push(['git', 'fetch', opts.remote])
			}
			if (opts.branch) {
				commands.push(['git', 'checkout', opts.branch])
				if (opts.remote) {
					commands.push(['git', 'pull', opts.remote, opts.branch])
				}
			}
			else if (opts.remote) {
				commands.push(['git', 'pull', opts.remote])
			}
			commands.push(['git', 'submodule', 'init'])
			commands.push(['git', 'submodule', 'update', '--recursive'])

			// Perform commands
			safeps.spawnMultiple(commands, opts, next)
		}

		// Check if it exists
		safefs.ensurePath(opts.cwd, function (err) {
			if (err) return next(err)

			// Initialise git repo
			safeps.spawn(['git', 'init'], opts, function (err) {
				if (err) return next(err)

				// If we want to set a remote, then do so
				if (opts.url && opts.remote) {
					// Check what remotes we have
					safeps.spawn(['git', 'remote', 'show'], opts, function (err, stdout) {
						if (err) return next(err)
						// stdout will be null if there are no remotes
						// and will be buffer if there are remotes
						if (stdout && stdout.toString().split('\n').indexOf(opts.remote) !== -1) {
							// Overwrite it if it does exist
							// @todo we could probably do a check here to see if it is different
							// but no need right now
							const command = ['git', 'remote', 'set-url', opts.remote, opts.url]
							safeps.spawn(command, opts, partTwo)
						}
						else {
							// Add it if it doesn't exist
							const command = ['git', 'remote', 'add', opts.remote, opts.url]
							safeps.spawn(command, opts, partTwo)
						}
					})
				}
				else {
					return partTwo()
				}
			})
		})

		// Chain
		return safeps
	},

	/**
	* Init Node Modules with cross platform support
	* supports linux, heroku, osx, windows
	* @param {Object} opts also forwarded to {@link spawn}
	* @param {Function} next {@link spawn} completion callback
	* @chainable
	* @return {this}
	*/
	initNodeModules (opts, next) {
		// Prepare
		[opts, next] = extractOptsAndCallback(opts, next)

		// Defaults
		if ( !opts.cwd )           opts.cwd = process.cwd()
		if ( opts.args == null )   opts.args = []
		if ( opts.force == null )  opts.force = false

		// Paths
		const packageJsonPath = pathUtil.join(opts.cwd, 'package.json')
		const nodeModulesPath = pathUtil.join(opts.cwd, 'node_modules')

		// Split this commands into parts
		function partTwo () {
			// If there is no package.json file, then we can't do anything
			safefs.exists(packageJsonPath, function (exists) {
				if ( !exists )  return next()

				// Prepare command
				const command = ['npm', 'install'].concat(opts.args)

				// Execute npm install inside the pugin directory
				safeps.spawn(command, opts, next)
			})
		}
		function partOne () {
			// If we are not forcing, then skip if node_modules already exists
			if ( !opts.force ) {
				safefs.exists(nodeModulesPath, function (exists) {
					if ( exists )  return next()
					partTwo()
				})
			}
			else {
				partTwo()
			}
		}

		// Run the first part
		partOne()

		// Chain
		return safeps
	},

	/**
	* Spawn Node Modules with cross platform support
	* supports linux, heroku, osx, windows
	* spawnNodeModule(name:string, args:array, opts:object, next:function)
	* Better than https://github.com/mafintosh/npm-execspawn as it uses safeps
	* @param {String} name
	* @param {Array} args
	* @param {Object} opts also forwarded to {@link spawn}
	* @param {String} opts.name name of node module
	* @param {String} [opts.cwd=process.cwd()] Current working directory of the child process.
	* @param {Function} next {@link spawn} completion callback
	* @chainable
	* @return {this}
	*/
	spawnNodeModule (...args) {
		// Prepare
		const opts = {cwd: process.cwd()}
		let next

		// Extract options
		for (let i = 0; i < args.length; ++i) {
			const arg = args[i]
			const type = typeof arg
			if ( Array.isArray(arg) ) {
				opts.args = arg
			}
			else if ( type === 'object' ) {
				if ( arg.next ) {
					next = arg.next
					arg.next = null
				}
				const keys = Object.keys(arg)
				for (let ii = 0; ii < keys.length; ++ii) {
					const key = keys[ii]
					opts[key] = arg[key]
				}
			}
			else if ( type === 'function' ) {
				next = arg
			}
			else if ( type === 'string' ) {
				opts.name = arg
			}
		}

		// Command
		let command
		if ( opts.name ) {
			command = [opts.name].concat(opts.args || [])
			opts.name = null
		}
		else {
			command = [].concat(opts.args || [])
		}

		// Clean up
		opts.args = null

		// Paths
		command[0] = pathUtil.join(opts.cwd, 'node_modules', '.bin', command[0])

		// Spawn
		safeps.spawn(command, opts, next)

		// Chain
		return safeps
	}
}

// =====================================
// Export

module.exports = safeps
