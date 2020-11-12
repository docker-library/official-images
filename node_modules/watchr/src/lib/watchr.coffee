# Require the node.js path module
# This provides us with what we need to interact with file paths
pathUtil = require('path')

# Require our helper modules
scandir = require('scandirectory')
fsUtil = require('safefs')
ignorefs = require('ignorefs')
extendr = require('extendr')
eachr = require('eachr')
extractOpts = require('extract-opts')
typeChecker = require('typechecker')
{TaskGroup} = require('taskgroup')
watchrUtil = require('./watchr-util')

# Require the node.js event emitter
# This provides us with the event system that we use for binding and trigger events
{EventEmitter} = require('events')

###
Now to make watching files more convient and managed, we'll create a class which we can use to attach to each file.
It'll provide us with the API and abstraction we need to accomplish difficult things like recursion.
We'll also store a global store of all the watchers and their paths so we don't have multiple watchers going at the same time
for the same file - as that would be quite ineffecient.
Events:
- `log` for debugging, receives the arguments `logLevel ,args...`
- `error` for gracefully listening to error events, receives the arguments `err`
- `watching` for when watching of the path has completed, receives the arguments `err, watcherInstance, isWatching`
- `change` for listening to change events, receives the arguments `changeType, fullPath, currentStat, previousStat`
###
watchersTotal = 0
watchers = {}
class Watcher extends EventEmitter
	# The path this class instance is attached to
	path: null

	# Our stat object, it contains things like change times, size, and is it a directory
	stat: null

	# The node.js file watcher instance, we have to open and close this, it is what notifies us of the events
	fswatcher: null

	# The watchers for the children of this watcher will go here
	# This is for when we are watching a directory, we will scan the directory and children go here
	children: null  # {}

	# We have to store the current state of the watcher and it is asynchronous (things can fire in any order)
	# as such, we don't want to be doing particular things if this watcher is deactivated
	# valid states are: pending, active, closed, deleted
	state: 'pending'

	# The method we will use to watch the files
	# Preferably we use watchFile, however we may need to use watch in case watchFile doesn't exist (e.g. windows)
	method: null

	# Configuration
	config:
		# A single path to watch
		path: null

		# Listener (optional, detaults to null)
		# single change listener, forwaded to @listen
		listener: null

		# Listeners (optional, defaults to null)
		# multiple event listeners, forwarded to @listen
		listeners: null

		# Stat (optional, defaults to `null`)
		# a file stat object to use for the path, instead of fetching a new one
		stat: null

		# Should we output log messages?
		outputLog: false

		# Interval (optional, defaults to `5007`)
		# for systems that poll to detect file changes, how often should it poll in millseconds
		# if you are watching a lot of files, make this value larger otherwise you will have huge memory load
		# only appliable to the `watchFile` watching method
		interval: 5007

		# Persistent (optional, defaults to `true`)
		# whether or not we should keep the node process alive for as long as files are still being watched
		# only appliable to the `watchFile` watching method
		persistent: true

		# Catchup Delay (optional, defaults to `1000`)
		# Because of swap files, the original file may be deleted, and then over-written with by moving a swap file in it's place
		# Without a catchup delay, we would report the original file's deletion, and ignore the swap file changes
		# With a catchup delay, we would wait until there is a pause in events, then scan for the correct changes
		catchupDelay: 2*1000

		# Preferred Methods (optional, defaults to `['watch','watchFile']`)
		# In which order should use the watch methods when watching the file
		preferredMethods: null

		# Follow symlinks, i.e. use stat rather than lstat. (optional, default to `true`)
		followLinks: true

		# Ignore Paths (optional, defaults to `false`)
		# array of paths that we should ignore
		ignorePaths: false

		# Ignore Hidden Files (optional, defaults to `false`)
		# whether or not to ignored files which filename starts with a `.`
		ignoreHiddenFiles: false

		# Ignore Common Patterns (optional, defaults to `true`)
		# whether or not to ignore common undesirable file patterns (e.g. `.svn`, `.git`, `.DS_Store`, `thumbs.db`, etc)
		ignoreCommonPatterns: true

		# Ignore Custom PAtterns (optional, defaults to `null`)
		# any custom ignore patterns that you would also like to ignore along with the common patterns
		ignoreCustomPatterns: null


	# Now it's time to construct our watcher
	# We give it a path, and give it some events to use
	# Then we get to work with watching it
	constructor: (opts,next) ->
		# Initialize our object variables for our instance
		@children = {}
		@config = extendr.extend({}, @config)
		@config.preferredMethods = ['watch', 'watchFile']

		# Extract options
		[opts, next] = extractOpts(opts, next)

		# Setup our instance with the configuration
		@setConfig(opts)  if opts

		# Start the watch setup
		@watch(next)  if next

		# Chain
		@

	# Set our configuration
	setConfig: (opts) ->
		# Apply
		extendr.extend(@config, opts)

		# Path
		@path = @config.path

		# Stat
		if @config.stat
			@stat = @config.stat
			@isDirectory = @stat.isDirectory()
			delete @config.stat

		# Listeners
		if @config.listener or @config.listeners
			@removeAllListeners()
			if @config.listener
				@listen(@config.listener)
				delete @config.listener
			if @config.listeners
				@listen(@config.listeners)
				delete @config.listeners

		# Chain
		@

	# Log
	log: (args...) =>
		# Prepare
		watchr = @
		config = @config

		# Output the log?
		console.log(args...)  if config.outputLog is true

		# Emit the log
		watchr.emit('log', args...)

		# Chain
		@

	# Get Ignored Options
	getIgnoredOptions: (opts={}) ->
		# Prepare
		config = @config

		# Return the ignore options
		return {
			ignorePaths: opts.ignorePaths ? config.ignorePaths
			ignoreHiddenFiles: opts.ignoreHiddenFiles ? config.ignoreHiddenFiles
			ignoreCommonPatterns: opts.ignoreCommonPatterns ? config.ignoreCommonPatterns
			ignoreCustomPatterns: opts.ignoreCustomPatterns ? config.ignoreCustomPatterns
		}

	# Is Ignored Path
	isIgnoredPath: (path,opts) =>
		# Prepare
		watchr = @

		# Ignore?
		ignore = ignorefs.isIgnoredPath(path, watchr.getIgnoredOptions(opts))

		# Log
		watchr.log('debug', "ignore: #{path} #{if ignore then 'yes' else 'no'}")

		# Return
		return ignore

	# Get the latest stat object
	# next(err, stat)
	getStat: (next) =>
		# Prepare
		watchr = @
		config = @config

		# Figure out what stat method we want to use
		method = if config.followLinks then 'stat' else 'lstat'

		# Fetch
		fsUtil[method](watchr.path, next)

		# Chain
		return @

	# Is Directory
	isDirectory: ->
		# Prepare
		watchr = @

		# Return is directory
		return watchr.stat.isDirectory()


	# Before we start watching, we'll have to setup the functions our watcher will need

	# Bubble
	# We need something to bubble events up from a child file all the way up the top
	bubble: (args...) =>
		# Prepare
		watchr = @

		# Log
		#watchr.log('debug',"bubble on #{@path} with the args:",args)

		# Trigger
		watchr.emit(args...)

		# Chain
		@

	# Bubbler
	# Setup a bubble wrapper
	bubbler: (eventName) =>
		# Prepare
		watchr = @

		# Return bubbler
		return (args...) -> watchr.bubble(eventName, args...)

	###
	Listen
	Add listeners to our watcher instance.
	Overloaded to also accept the following:
	- `changeListener` a single change listener
	- `[changeListener]` an array of change listeners
	- `{eventName:eventListener}` an object keyed with the event names and valued with a single event listener
	- `{eventName:[eventListener]}` an object keyed with the event names and valued with an array of event listeners
	###
	listen: (eventName,listener) ->
		# Prepare
		watchr = @

		# Check format
		unless listener?
			# Alias
			listeners = eventName

			# Array of change listeners
			if typeChecker.isArray(listeners)
				for listener in listeners
					watchr.listen('change', listener)

			# Object of event listeners
			else if typeChecker.isPlainObject(listeners)
				for own eventName,listenerArray of listeners
					# Array of event listeners
					if typeChecker.isArray(listenerArray)
						for listener in listenerArray
							watchr.listen(eventName, listener)
					# Single event listener
					else
						watchr.listen(eventName, listenerArray)

			# Single change listener
			else
				watchr.listen('change', listeners)
		else
			# Listen
			watchr.removeListener(eventName, listener)
			watchr.on(eventName, listener)
			watchr.log('debug', "added a listener: on #{watchr.path} for event #{eventName}")

		# Chain
		@

	###
	Listener
	A change event has fired

	Things to note:
	- watchFile method
		- Arguments
			- currentStat - the updated stat of the changed file
				- Exists even for deleted/renamed files
			- previousStat - the last old stat of the changed file
				- Is accurate, however we already have this
		- For renamed files, it will will fire on the directory and the file
	- watch method
		- Arguments
			- eventName - either 'rename' or 'change'
				- THIS VALUE IS ALWAYS UNRELIABLE AND CANNOT BE TRUSTED
			- filename - child path of the file that was triggered
				- This value can also be unrealiable at times
	- Both methods
		- For deleted and changed files, it will fire on the file
		- For new files, it will fire on the directory

	Output arguments for your emitted event will be:
	- for updated files the arguments will be: `'update', fullPath, currentStat, previousStat`
	- for created files the arguments will be: `'create', fullPath, currentStat, null`
	- for deleted files the arguments will be: `'delete', fullPath, null, previousStat`

	In the future we will add:
	- for renamed files: 'rename', fullPath, currentStat, previousStat, newFullPath
	- rename is possible as the stat.ino is the same for the delete and create
	###
	listenerTasks: null
	listenerTimeout: null
	listener: (opts, next) =>
		# Prepare
		watchr = @
		config = @config
		[opts, next] = extractOpts(opts, next)

		# Prepare properties
		currentStat = null
		fileExists = null
		previousStat = watchr.stat

		# Log
		watchr.log('debug', "Watch triggered on: #{watchr.path}")

		# Delay the execution of the listener tasks, to once the change events have stopped firing
		clearTimeout(watchr.listenerTimeout)  if watchr.listenerTimeout?
		watchr.listenerTimeout = setTimeout(
			->
				listenerTasks = watchr.listenerTasks
				watchr.listenerTasks = null
				watchr.listenerTimeout = null
				listenerTasks.run()
			config.catchupDelay or 0
		)

		# We are a subsequent listener, in which case, just listen to the first listener tasks
		if watchr.listenerTasks?
			watchr.listenerTasks.done(next)  if next
			return @

		# Start the detection process
		watchr.listenerTasks = tasks = new TaskGroup().done (err) ->
			watchr.listenersExecuting -= 1
			watchr.emit('error', err)  if err
			return next?(err)

		# Check if the file still exists
		tasks.addTask (complete) ->
			# Log
			watchr.log('debug', "Watch followed through on: #{watchr.path}")

			# Check if the file still exists
			fsUtil.exists watchr.path, (exists) ->
				# Apply local gobal property
				fileExists = exists

				# If the file still exists, then update the stat
				if fileExists is false
					# Log
					watchr.log('debug', "Determined delete: #{watchr.path}")

					# Apply
					watchr.close('deleted')
					watchr.stat = null

					# Clear the remaining tasks, as they are no longer needed
					tasks.clearRemaining()
					return complete()

				# Update the stat of the file
				watchr.getStat (err, stat) ->
					# Check
					return watchr.emit('error', err)  if err

					# Update
					watchr.stat = currentStat = stat

					# If there is a new file at the same path as the old file, then recreate the watchr
					if watchr.stat.birthtime isnt previousStat.birthtime
						createWatcher(@, complete)
					else
						# Get on with it
						return complete()

		# Check if the file has changed
		tasks.addTask ->
			# Check if it is the same
			# as if it is, then nothing has changed, so ignore
			if watchrUtil.statChanged(previousStat, currentStat) is false
				watchr.log('debug', "Determined same: #{watchr.path}", previousStat, currentStat)

				# Clear the remaining tasks, as they are no longer needed
				tasks.clearRemaining()

		# Check what has changed
		tasks.addGroup (addGroup, addTask, complete) ->
			# Set this sub group to execute in parallel
			@setConfig(concurrency: 0)

			# So let's check if we are a directory
			if watchr.isDirectory() is false
				# If we are a file, lets simply emit the change event
				watchr.log('debug', "Determined update: #{watchr.path}")
				watchr.emit('change', 'update', watchr.path, currentStat, previousStat)
				return complete()

			# We are a direcotry
			# Chances are something actually happened to a child (rename or delete)
			# and if we are the same, then we should scan our children to look for renames and deletes
			fsUtil.readdir watchr.path, (err,newFileRelativePaths) ->
				# Error?
				return complete(err)  if err

				# The watch method is fast, but not reliable, so let's be extra careful about change events
				if watchr.method is 'watch'
					eachr watchr.children, (childFileWatcher,childFileRelativePath) ->
						# Skip if the file has been deleted
						return  unless childFileRelativePath in newFileRelativePaths
						return  unless childFileWatcher
						tasks.addTask (complete) ->
							watchr.log('debug', "Forwarding extensive change detection to child: #{childFileRelativePath} via: #{watchr.path}")
							childFileWatcher.listener(null, complete)
						return

				# Find deleted files
				eachr watchr.children, (childFileWatcher,childFileRelativePath) ->
					# Skip if the file still exists
					return  if childFileRelativePath in newFileRelativePaths

					# Fetch full path
					childFileFullPath = pathUtil.join(watchr.path, childFileRelativePath)

					# Skip if ignored file
					if watchr.isIgnoredPath(childFileFullPath)
						watchr.log('debug', "Ignored delete: #{childFileFullPath} via: #{watchr.path}")
						return

					# Emit the event and note the change
					watchr.log('debug', "Determined delete: #{childFileFullPath} via: #{watchr.path}")
					watchr.closeChild(childFileRelativePath, 'deleted')
					return

				# Find new files
				eachr newFileRelativePaths, (childFileRelativePath) ->
					# Skip if we are already watching this file
					return  if watchr.children[childFileRelativePath]?
					watchr.children[childFileRelativePath] = false  # reserve this file

					# Fetch full path
					childFileFullPath = pathUtil.join(watchr.path, childFileRelativePath)

					# Skip if ignored file
					if watchr.isIgnoredPath(childFileFullPath)
						watchr.log('debug', "Ignored create: #{childFileFullPath} via: #{watchr.path}")
						return

					# Emit the event and note the change
					addTask (complete) ->
						watchr.log('debug', "Determined create: #{childFileFullPath} via: #{watchr.path}")
						watchr.watchChild(
							fullPath: childFileFullPath,
							relativePath: childFileRelativePath,
							next: (err, childFileWatcher) ->
								return complete(err)  if err
								watchr.emit('change', 'create', childFileFullPath, childFileWatcher.stat, null)
								return complete()
						)
					return

				# Read the directory, finished adding tasks to the group
				return complete()

		# Tasks are executed via the timeout thing earlier

		# Chain
		@

	###
	Close
	We will need something to close our listener for removed or renamed files
	As renamed files are a bit difficult we will want to close and delete all the watchers for all our children too
	Essentially it is a self-destruct
	###
	close: (reason) ->
		# Prepare
		watchr = @

		# Nothing to do? Already closed?
		return @  if watchr.state isnt 'active'

		# Close
		watchr.log('debug', "close: #{watchr.path}")

		# Close our children
		for own childRelativePath of watchr.children
			watchr.closeChild(childRelativePath, reason)

		# Close watchFile listener
		if watchr.method is 'watchFile'
			fsUtil.unwatchFile(watchr.path)

		# Close watch listener
		if watchr.fswatcher?
			watchr.fswatcher.close()
			watchr.fswatcher = null

		# Updated state
		if reason is 'deleted'
			watchr.state = 'deleted'
			watchr.emit('change', 'delete', watchr.path, null, watchr.stat)
		else if reason is 'failure'
			watchr.state = 'closed'
			watchr.log('warn', "Failed to watch the path #{watchr.path}")
		else
			watchr.state = 'closed'

		# Delete our watchers reference
		if watchers[watchr.path]?
			delete watchers[watchr.path]
			watchersTotal--

		# Chain
		@

	# Close a child
	closeChild: (fileRelativePath,reason) ->
		# Prepare
		watchr = @

		# Check
		if watchr.children[fileRelativePath]?
			watcher = watchr.children[fileRelativePath]
			watcher.close(reason)  if watcher  # could be "fase" for reservation
			delete watchr.children[fileRelativePath]

		# Chain
		@

	###
	Watch Child
	Setup watching for a child
	Bubble events of the child into our instance
	Also instantiate the child with our instance's configuration where applicable
	next(err, watchr)
	###
	watchChild: (opts, next) ->
		# Prepare
		watchr = @
		config = @config
		[opts, next] = extractOpts(opts, next)

		# Check if we are already watching
		if watchr.children[opts.relativePath]
			# Provide the existing watcher
			next?(null, watchr.children[opts.relativePath])
		else
			# Create a new watcher for the child
			watchr.children[opts.relativePath] = watch(
				# Custom
				path: opts.fullPath
				stat: opts.stat
				listeners:
					'log': watchr.bubbler('log')
					'change': (args...) ->
						[changeType, path] = args
						if changeType is 'delete' and path is opts.fullPath
							watchr.closeChild(opts.relativePath, 'deleted')
						watchr.bubble('change', args...)
					'error': watchr.bubbler('error')
				next: next

				# Inherit
				outputLog: config.outputLog
				interval: config.interval
				persistent: config.persistent
				catchupDelay: config.catchupDelay
				preferredMethods: config.preferredMethods
				ignorePaths: config.ignorePaths
				ignoreHiddenFiles: config.ignoreHiddenFiles
				ignoreCommonPatterns: config.ignoreCommonPatterns
				ignoreCustomPatterns: config.ignoreCustomPatterns
				followLinks: config.followLinks
			)

		# Return the watchr
		return watchr.children[opts.relativePath]

	###
	Watch Children
	next(err, watching)
	###
	watchChildren: (next) ->
		# Prepare
		watchr = @
		config = @config

		# Cycle through the directory if necessary
		if watchr.isDirectory()
			scandir(
				# Path
				path: watchr.path

				# Options
				ignorePaths: config.ignorePaths
				ignoreHiddenFiles: config.ignoreHiddenFiles
				ignoreCommonPatterns: config.ignoreCommonPatterns
				ignoreCustomPatterns: config.ignoreCustomPatterns
				recurse: false

				# Next
				next: (err) ->
					watching = !err
					return next(err, watching)

				# File and Directory Actions
				action: (fullPath,relativePath,nextFile) ->
					# Check we are still releveant
					if watchr.state isnt 'active'
						return nextFile(null, true)  # skip without error

					# Watch this child
					watchr.watchChild {fullPath, relativePath}, (err,watcher) ->
						return nextFile(err)
			)

		else
			next(null, true)

		# Chain
		@

	###
	Watch Self
	next(err, watching)
	###
	watchSelf: (next) ->
		# Prepare
		watchr = @
		config = @config

		# Reset the method
		watchr.method = null

		# Try the watch
		watchrUtil.watchMethods(
			path: watchr.path
			methods: config.preferredMethods
			persistent: config.persistent
			interval: config.interval
			listener: -> watchr.listener()
			next: (err, success, method, fswatcher) ->
				# Check
				watchr.fswatcher = fswatcher
				watchr.emit('error', err)  if err

				# Error?
				if !success
					watchr.close('failure')
					return next(null, false)

				# Apply
				watchr.method = method
				watchr.state = 'active'

				# Forward
				return next(null, true)
		)

		# Chain
		@

	###
	Watch
	Setup the native watching handlers for our path so we can receive updates on when things happen
	If the next argument has been received, then add it is a once listener for the watching event
	If we are already watching this path then let's start again (call close)
	If we are a directory, let's recurse
	If we are deleted, then don't error but return the isWatching argument of our completion callback as false
	Once watching has completed for this directory and all children, then emit the watching event
	next(err, watchr, watching)
	###
	watch: (next) ->
		# Prepare
		watchr = @
		config = @config

		# Prepare
		complete = (err, watching) ->
			# Prepare
			err ?= null
			watching ?= true

			# Failure
			if err or !watching
				watchr.close()
				next?(err, watchr, false)
				watchr.emit('watching', err,  watchr, false)

			# Success
			else
				next?(null, watchr, true)
				watchr.emit('watching', null, watchr, true)

		# Ensure Stat
		if watchr.stat? is false
			# Fetch the stat
			watchr.getStat (err, stat) ->
				# Error
				return complete(err, false)  if err or !stat

				# Apply
				watchr.stat = stat

				# Recurse
				return watchr.watch(next)

			# Chain
			return @

		# Close our all watch listeners
		watchr.close()

		# Log
		watchr.log('debug', "watch: #{@path}")

		# Watch ourself
		watchr.watchSelf (err, watching) ->
			return complete(err, watching)  if err or !watching

			# Watch the childrne
			watchr.watchChildren (err, watching) ->
				return complete(err, watching)

		# Chain
		@


###
Create Watcher
Checks to see if the path actually exists, if it doesn't then exit gracefully
If it does exist, then lets check our cache for an already existing watcher instance
If we have an already existing watching instance, then just add our listeners to that
If we don't, then create a watching instance
Fire the next callback once done
opts = {path, listener, listeners}
opts = watcher instance
next(err,watcherInstance)
###
createWatcher = (opts,next) ->
	# Prepare
	[opts, next] = extractOpts(opts, next)

	# Only create a watchr if the path exists
	unless fsUtil.existsSync(opts.path)
		next?(null, null)
		return

	# Should we clone a watcher instance?
	# By copying relevant configuration, closing the old watcher, and creating a new
	if opts instanceof Watcher
		opts.close()
		opts = extendr.extend({}, opts.config, {
			listener: opts.listener,
			listeners: opts.listeners
		})
		# continue to create a new, watchers[opts.path] should be deleted now due to opts.close

	# Use existing
	if watchers[opts.path]?
		# We do, so let's use that one instead
		watcher = watchers[opts.path]

		# and add the new listeners if we have any
		watcher.listen(opts.listener)   if opts.listener
		watcher.listen(opts.listeners)  if opts.listeners

		# as we don't create a new watcher, we must fire the next callback ourselves
		next?(null, watcher)

	# Create a new one
	else
		# We don't, so let's create a new one
		attempt = 0
		watcher = new Watcher opts, (err) ->
			# Continue if we passed
			return next?(err, watcher)  if !err or attempt isnt 0
			++attempt

			# Log
			watcher.log('debug', "Preferred method failed, trying methods in reverse order", err)

			# Otherwise try again with the other preferred method
			watcher
				.setConfig(
					preferredMethods: watcher.config.preferredMethods.reverse()
				)
				.watch()

		# Save the watcher
		watchers[opts.path] = watcher
		++watchersTotal

	# Return
	return watcher


###
Watch
Provides an abstracted API that supports multiple paths
If you are passing in multiple paths then do not rely on the return result containing all of the watchers
you must rely on the result inside the completion callback instead
If you used the paths option, then your results will be an array of watcher instances, otherwise they will be a single watcher instance
next(err,results)
###
watch = (opts,next) ->
	# Prepare
	[opts, next] = extractOpts(opts, next)

	# Prepare
	result = []

	# Check paths as that is handled by us
	if opts.paths
		# Extract it and delte it from the opts
		paths = opts.paths
		delete opts.paths

		# Check its format
		if typeChecker.isArray(paths)
			# Prepare
			tasks = new TaskGroup(concurrency:0).whenDone (err) ->
				next?(err, result)
			paths.forEach (path) ->
				tasks.addTask (complete) ->
					localOpts = extendr.extend({}, opts, {path})
					watcher = createWatcher(localOpts,complete)
					result.push(watcher)  if watcher
			tasks.run()

		# Paths is actually a single path
		else
			opts.path = paths
			result.push createWatcher opts, (err) ->
				next?(err, result)

	# Single path
	else
		result = createWatcher(opts, next)

	# Return
	return result

# Now let's provide node.js with our public API
# In other words, what the application that calls us has access to
module.exports = {
	watch: watch
	Watcher: Watcher
}
