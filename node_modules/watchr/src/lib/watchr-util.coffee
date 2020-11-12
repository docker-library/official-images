# Import
extendr = require('extendr')
extractOpts = require('extract-opts')
fsUtil = require('safefs')

# Define
watchrUtil =
	# Stat Changed
	statChanged: (old, current) ->
		# Has the file been deleted or created?
		if old? isnt current?
			return true

		# Has the file contents changed?
		else if old? and current?
			old = extendr.dereferenceJSON(old)
			current = extendr.dereferenceJSON(current)

			delete old.atime  if old.atime?
			delete old.ctime  if old.ctime?
			delete current.atime  if current.atime?
			delete current.ctime  if current.ctime?

			# The files contents have actually changed
			if JSON.stringify(old) isnt JSON.stringify(current)
				return true

			# The files contents are the same
			else
				return false

		# The file still does not exist
		else
			return false

	# Try fsUtil.watch
	# opts = {path, listener}
	# next(err, success, 'watch', fswatcher)
	watch: (opts, next) ->
		# Prepare
		[opts, next] = extractOpts(opts, next)

		# Check
		return next(null, false, 'watch')  unless fsUtil.watch?

		# Watch
		try
			fswatcher = fsUtil.watch(opts.path, opts.listener)
			# must pass the listener here instead of doing fswatcher.on('change', opts.listener)
			# as the latter is not supported on node 0.6 (only 0.8+)
		catch err
			return next(err, false, 'watch', fswatcher)

		# Apply
		return next(null, true, 'watch', fswatcher)

	# Try fsUtil.watchFile
	# opts = {path, persistent?, interval?, listener}
	# next(err, success, 'watchFile')
	watchFile: (opts, next) ->
		# Prepare
		[opts, next] = extractOpts(opts, next)

		# Check
		return next(null, false, 'watchFile')  unless fsUtil.watchFile?

		# Watch
		try
			fsUtil.watchFile(opts.path, {persistent: opts.persistent, interval: opts.interval}, opts.listener)
		catch err
			return next(err, false, 'watchFile')

		# Apply
		return next(null, true, 'watchFile')

	# Try one watch method first, then try the other
	# opts = {path, methods?, parsistent?, interval?, listener}
	# next(err, success, method, fswatcher?)
	watchMethods: (opts, next) ->
		# Prepare
		[opts, next] = extractOpts(opts, next)

		# Prepare
		opts.methods ?= ['watch', 'watchFile']

		# Preferences
		methodOne = watchrUtil[opts.methods[0]]
		methodTwo = watchrUtil[opts.methods[1]]

		# Try first
		methodOne opts, (errOne, success, method, fswatcher) ->
			# Move on if succeeded
			return next(null, success, method, fswatcher)  if success
			# Otherwise...

			# Try second
			methodTwo opts, (errTwo, success, method, fswatcher) ->
				# Move on if succeeded
				return next(null, success, method, fswatcher)  if success
				# Otherwise...

				# Log errors and fail
				errCombined = new Error("Both watch methods failed on #{opts.path}:\n#{errOne.stack.toString()}\n#{errTwo.stack.toString()}")
				return next(errCombined, false, null, fswatcher)

		# Chain
		return @

module.exports = watchrUtil
