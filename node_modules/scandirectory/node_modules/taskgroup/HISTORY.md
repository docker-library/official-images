# History

## v4.3.1 2015 December 10
- Removed `cyclic.js` as the problem it solved was solved by npm v2 and above

## v4.3.0 March 15, 2015
- Module.exports now exports the TaskGroup class, of which `Task` and `TaskGroup` are now children
- Added `Task` attribute on the TaskGroup class to allow over-riding of what should be the sub-task class
- Added `TaskGroup` attribute on the TaskGroup class to allow over-riding of what should be the sub-taskgroup class
- Added the `sync` configuration option, which when set to `true` will allow the execution of a Task or TaskGroup to execute synchronously
- Updated dependencies

## v4.2.1 February 20, 2015
- Output more information about errors when a task completes twice

## v4.2.0 February 2, 2015
- Reintroduced `try...catch` for Node v0.8 and browser environments with a workaround to prevent error suppression
	- Thanks to [kksharma1618](https://github.com/kksharma1618) for [issue #17](https://github.com/bevry/taskgroup/issues/17)
	- Closes [issue #18](https://github.com/bevry/taskgroup/issues/17)
- You can now ignore all the warnings from the v4.1.0 changelog as the behaviour is more or less the same as v4.0.5 but with added improvements

## v4.1.0 February 2, 2015
- This release fixes the errors in completion callbacks being swallowed/lost
	- Thanks to [kksharma1618](https://github.com/kksharma1618) for [issue #17](https://github.com/bevry/taskgroup/issues/17)
- The following changes have been made
	- We no longer use `try...catch` at all, if you want error catching in your task, you must not disable domains (they are enabled by default) - [why?](https://github.com/bevry/taskgroup/issues/17#issuecomment-72383610)
	- We now force exit the domain when the task's method calls its completion callback
	- Domains now wrap only the firing of the task's method, rather than the preparation too as before
	- Removed superflous check to ensure a task has a method before execution
	- Ensured the actual check to ensure a task has a method before execution also checks if the method is actually a function (via checking for `.bind`) as the superflous check did
- This **could** introduce the following issues in the following cases:
	- You may get errors that were suppressed before now showing themselves, this is good, but it may cause unexpected things to break loudly that were breaking silently before
	- If you have domains disabled and an error is thrown, you will get a different flow of logic than before as the error will be caught in your code, not TaskGroup's
	- The domain's flow has improved, but this may cause a different flow than you were expecting previously
- This **will** introduce the following issues in the following cases:
 	- If you are still on Node v0.8, synchronous errors and perhaps asynchronous errors thrown within your task method will no longer be caught by TaskGroup (due to Node 0.8's crippled domain functionality) and instead will need to be caught by your code either via preferably sent to the task method's completion callback rather than thrown, or via your own try...catch. But please upgrade to Node 0.10 or higher.
	- If you are running TaskGroup in a web browser, you will need to catch errors manually or utilise a domain shim (browserify has one by default) - [why?](https://github.com/bevry/taskgroup/issues/18)
- In other words, this release is the most stable yet, but do run your tests (you should always do this)

## v4.0.5 August 3, 2014
- Changed an error output to be of error type

## v4.0.4 August 3, 2014
- Added the ability to turn off using domains by setting the new task option `domain` to `false` (defaults to `true`)
- Added the ability to turn off using [ambi](https://github.com/bevry/ambi) by setting the new task option `ambi` to `false` (defaults to `true`)

## v4.0.3 July 11, 2014
- Use `setImmediate` instead of `nextTick` to avoid `(node) warning: Recursive process.nextTick detected. This will break in the next version of node. Please use setImmediate for recursive deferral.` errors
- Updated dependencies

## v4.0.2 June 18, 2014
- Added support for `done`, `whenDone`, `onceDone`, `once`, and `on` configuration options

## v4.0.1 June 16, 2014
- Fixed `Recursive process.nextTick detected` error (regression since v4.0.0)

## v4.0.0 June 16, 2014
- Significant rewrite with b/c breaks
	- Completion listeners should now be accomplished via `.done(listener)` (listens once) or `.whenDone(listener)` (listener persists)
		- These methods are promises in that they will execute the listener if the item is already complete
		- They listen for the `done` event
	- The execution of tasks and groups have had a great deal of investment to ensure execution is intuitive and consistent across different use cases
		- Refer to to `src/lib/test/taskgroup-usage-test.coffee` for the guaranteed expectations across different scenarios
	- In earlier versions you could use `tasks.exit()` during execution to clear remaning items, stop execution, and exit, you can no longer do this, instead use the completion callback with an error, or call `tasks.clear()` then the completion callback
	- Refer to the [new public api docs](http://learn.bevry.me/taskgroup/api) for the latest usage
- Changes
	- `complete` event is now `completed`, but you really should be using the new `done` event or the promise methods
	- `run` event is now `started`
	- A lot of internal variables and methods have had their functionality changed or removed, if a method or variable is not in the [public api](http://learn.bevry.me/taskgroup/api), do not use it
	- There is now a default `error` and `completed` listener that will emit the `done` event if there are listeners for it, if there is no `done` event listeners, and an error has occured, we will throw the error
	- Tasks and groups will now only receive a default name when required, this is to prevent set names from being over-written by the default
	- Adding of tasks and groups to a group instance will now return the group instance rather than the added tasks to ensure chainability, if you want the created tasks, use `.createTask(...)` and `.createGroup(...)` instead, then add the result manually
- Introductions
	- `passed`, `failed`, `destroyed` events are new
	- Task only
		- new `timeout` option that accepts a number of milliseconds to wait before throwing an error
		- new `onError` option that defaults to `'exit'` but can also accept `'ignore'` which will ignore duplicated exit errors (useful when combined with timeout event)
	- TaskGroup only
		- new `onError` option that defaults to `'exit'` but can also accept `'ignore'` which will ignore all task errors
		- new `setNestedConfig(config)` and `setNestedTaskConfig(config)` options to set configuration for all children

## v3.4.0 May 8, 2014
- Added `context` option for Task, to perform a late bind on the method
- Asynchronous task methods can now accept optional arguments thanks to new [ambi](https://github.com/bevry/ambi) version
- Updated dependencies

## v3.3.9 May 4, 2014
- Added [extendonclass](https://github.com/bevry/extendonclass) support
- Added `Task.create` and `TaskGroup.create` helpers
- Will no longer fall over if an invalid argument is passed as configuration
- Updated dependencies

## v3.3.8 February 5, 2014
- More descriptive error when a task is fired without a method to fire

## v3.3.7 January 30, 2014
- Improvements around adding tasks to task groups and passing arguments to Task and TaskGroup constructors

## v3.3.6 November 29, 2013
- Properly fixed v3.3.3 issue while maintaining node.js v0.8 and browserify support
	- Thanks to [pflannery](https://github.com/pflannery) for [pull request #11](https://github.com/bevry/taskgroup/pull/11)

## v3.3.5 November 28, 2013
- Re-added Node.js v0.8 support (regression since v3.3.3)

## v3.3.4 November 27, 2013
- Fixed the v3.3.3 fix

## v3.3.3 November 27, 2013
- Fixed possible "(node) warning: Recursive process.nextTick detected. This will break in the next version of node. Please use setImmediate for recursive deferral." error under certain circumstances

## v3.3.2 November 19, 2013
- Don't add or create empty tasks and groups

## v3.3.1 November 6, 2013
- Fixed child event bubbling by using duck typing (regression since v3.3.0)
- Better error handling on uncaught task exceptions
- Tasks will now get a default name set to ease debugging

## v3.3.0 November 1, 2013
- Bindings are now more explicit
- Improved configuration parsing
- Configuration is now accessed via `getConfig()`
- Dropped component.io and bower support, just use ender or browserify

## v3.2.4 October 27, 2013
- Re-packaged

## v3.2.3 September 18, 2013
- Fixed cyclic dependency problem on windows (since v2.1.3)
- Added bower support

## v3.2.2 September 18, 2013
- Component.io compatibility

## v3.2.1 August 19, 2013
- Republish with older verson of joe dev dependency to try and stop cyclic errors
- Better node 0.8 support when catching thrown errors

## v3.2.0 August 19, 2013
- Wrapped Task execution in a domain to catch uncaught errors within the task execution, as well as added checks to ensure the completion callback does not fire multiple times
	- These will be reported via the `error` event that the Task will emit
		- If the Task is part of a TaskGroup, the TaskGroup will listen for this, kill the TaskGroup and emit an `error` event on the TaskGroup
- Moved from EventEmitter2 to node's own EventEmitter to ensure domain compatibility

## v3.1.2 April 6, 2013
- Added `getTotals()` to `TaskGroup`
- Added `complete()` to `Task`

## v3.1.1 April 5, 2013
- Fixed task run issue under certain circumstances
- Added `exit(err)` function

## v3.1.0 April 5, 2013
- Tasks can now have the arguments that are sent to them customized by the `args` configuration option
- Group inline functions now support an optional completion callback
- Group events for items now have their first argument as the item the event was for

## v3.0.0 April 5, 2013
- Significant rewrite and b/c break

## v2.0.0 March 27, 2013
- Split from bal-util

## v1.16.14 March 27, 2013
- Killed explicit browser support, use [Browserify](http://browserify.org/) instead
- Removed the `out` directory from git
- Now compiled with the coffee-script bare option

## v1.16.13 March 23, 2013
- `balUtilEvents` changes:
	- `EventEmitterEnhanced` changes:
		- Now works with `once` calls in node 0.10.0
			- Closes [bevry/docpad#462](https://github.com/bevry/docpad/issues/462)
		- Changed `emitSync` to be an alias to `emitSerial` and `emitAsync` to be an alias to `emitParallel`
		- Added new `getListenerGroup` function
- `balUtilFlow` changes:
	- `fireWithOptionalCallback` can now take the method as an array of `[fireMethod,introspectMethod]`  useful for pesly binds

## v1.16.12 March 18, 2013
- `balUtilFlow` changes:
	- `Groups::run` signature changed from no arguments to a single `mode` argument

## v1.16.11 March 10, 2013
- `balUtilModules` changes:
	- Fixed `getCountryCode` and `getLanguageCode` failing when there is no locale code

## v1.16.10 March 8, 2013
- `balUtilModules` changes:
	- Fixed `requireFresh` regression, added test

## v1.16.9 March 8, 2013
- `balUtilModules` changes:
	- Added `getLocaleCode`
	- Added `getCountryCode`
	- Added `getLanguageCode`

## v1.16.8 February 16, 2013
- `balUtilModules` changes:
	- `spawnMultiple`, `execMultiple`: now accept a `tasksMode` option that can be `serial` (default) or `parallel`

## v1.16.7 February 12, 2013
- `balUtilPaths` changes:
	- `readPath`: do not prefer gzip, but still support it for decoding, as the zlib library is buggy

## v1.16.6 February 12, 2013
- `balUtilPaths` changes:
	- `readPath`: add support for gzip decoding for node 0.6 and higher

## v1.16.5 February 6, 2013
- More [browserify](http://browserify.org/) support

## v1.16.4 February 6, 2013
- [Browserify](http://browserify.org/) support

## v1.16.3 February 5, 2013
- Node v0.4 support
- `balUtilPaths` changes:
	- Removed deprecated `console.log`s when errors occur (they are now sent to the callback)
	- Fixed `determineExecPath` when executable requires the environment configuration
- `balUtilTypes` changes:
	- `isEmptyObject` now works for empty values (e.g. `null`)
- `balUtilFlow` changes:
	- Added `clone`
	- Added `deepClone`
	- `setDeep` and `getDeep` now handle `undefined` values correctly

## v1.16.2 February 1, 2013
- `balUtilPaths` changes:
	- Added timeout support to `readPath`
- `balUtilFlow` changes:
	- Added `setDeep`
	- Added `getDeep`

## v1.16.1 January 25, 2013
- `balUtilFlow` changes:
	- Added `safeShallowExtendPlainObjects`
	- Added `safeDeepExtendPlainObjects`

## v1.16.0 January 24, 2013
- Node v0.9 compatability
- `balUtilModules` changes:
	- Added `getEnvironmentPaths`
	- Added `getStandardExecPaths(execName)`
	- `exec` now supports the `output` option
	- `determineExecPath` now resolves the possible paths and checks for their existance
		- This avoids Node v0.9's ENOENT crash when executing a path that doesn't exit
	- `getExecPath` will now try for `.exe` paths as well when running on windows if an extension hasn't already been defined
	- `getGitPath`, `getNodePath`, `getNpmPath` will now also check the environment paths
- `balUtilFlow` changes:
	- Added `createSnore`
	- Added `suffixArray`
	- `flow` now accepts the signatures `({object,actions,action,args,tasks,next})`, `(object, action, args, next)` and `(actions,args,next)`
	- `Group` changes:
		- `mode` can now be either `parallel` or `serial`, rather than `async` and `sync`
		- `async()` is now `parallel()` (aliased for b/c)
		- `sync()` is now `serial()` (aliased for b/c)
- `balUtilTypes` changes:
	- Added `isEmptyObject`

## v1.15.4 January 8, 2013
- `balUtilPaths` changes:
	- Renamed `testIgnorePatterns` to `isIgnoredPath`
		- Added aliases for b/c compatibility
	- Added new `ignorePaths` option

## v1.15.3 December 24, 2012
- `balUtilModules` changes:
	- Added `requireFresh`

## v1.15.2 December 16, 2012
- `balUtilPaths` changes:
	- Fixed `scandir` not inheriting ignore patterns when recursing

## v1.15.1 December 15, 2012
- `balUtilPaths` changes:
	- Fixed `testIgnorePatterns` when `ignoreCommonPatterns` is set to `true`

## v1.15.0 December 15, 2012
- `balUtilPaths` changes:
	- Added `testIgnorePatterns`
	- Renamed `ignorePatterns` to `ignoreCommonPatterns`, and added new `ignoreCustomPatterns`
		- Affects `scandir` options
	- Added emac cache files to `ignoreCommonPatterns`

## v1.14.1 December 14, 2012
- `balUtilModules` changes:
	- Added `getExecPath` that will fetch an executable path based on the paths within the environment `PATH` variable
- Rebuilt with CoffeeScript 1.4.x

## v1.14.0 November 23, 2012
- `balUtilPaths` changes:
	- `readPath` will now follow url redirects

## v1.13.13 October 26, 2012
- `balUtilPaths` changes:
	- Files that start with `~` are now correctly ignored in `commonIgnorePatterns`

## v1.13.12 October 22, 2012
- `balUtilFlow` changes:
	- `extend` is now an alias of `shallowExtendPlainObjects` as they were exactly the same
- `balUtilHTML` changes:
	- `replaceElement` and `replaceElementAsync` changes:
		- now accept arguments in object form as well
		- accept a `removeIndentation` argument that defaults to `true`

## v1.13.11 October 22, 2012
- `balUtilPaths` changes:
	- `ensurePath` now returns `err` and `exists` instead of just `err`
- `balUtilModules` changes:
	- `initGitRepo` will now default `remote` to `origin` and `branch` to `master`
	- Added `initOrPullGitRepo`

## v1.13.10 October 7, 2012
- `balUtilPaths` changes:
	- Added `shallowExtendPlainObjects`

## v1.13.9 October 7, 2012
- `balUtilPaths` changes:
	- VIM swap files now added to `commonIgnorePatterns`
		- Thanks to [Sean Fridman](https://github.com/sfrdmn) for [pull request #4](https://github.com/balupton/bal-util/pull/4)

## v1.13.8 October 2, 2012
- `balUtilModules` changes:
	- Added `openProcess` and `closeProcess`, and using them in `spawn` and `exec`, used to prevent `EMFILE` errors when there are too many open processes
	- Max number of open processes is configurable via the `NODE_MAX_OPEN_PROCESSES` environment variable
	` balUtilPaths` changes:
	- Max number of open files is now configurable via the`NODE_MAX_OPEN_FILES` environment variable

## v1.13.7 September 24, 2012
- `balUtilPaths` changes:
	- Added `textExtensions` and `binaryExtensions`
		- The environment variables `TEXT_EXTENSIONS` and `BINARY_EXTENSIONS` will append to these arrays
	- Added `isText` and `isTextSync`

## v1.13.6 September 18, 2012
- `balUtilPaths` changes:
	- Improved `getEncoding`/`getEncodingSync` detection
		- Will now scan start, middle and end, instead of just middle

## v1.13.5 September 13, 2012
- `balUtilPaths` changes:
	- Added `getEncoding` and `getEncodingSync`

## v1.13.4 August 28, 2012
- `balUtilModules` changes:
	- Failing to retrieve the path on `getGitPath`, `getNodePath` and `getNpmPath` will now result in an error

## v1.13.3 August 28, 2012
- `balUtilModules` changes:
	- Fixed `exec` and `execMultiple`
	- Added `gitCommands`, `nodeCommands` and `npmCommands`
- Dropped node v0.4 support, min required version now 0.6

## v1.13.2 August 16, 2012
- Repackaged

## v1.13.1 August 16, 2012
- `balUtilHTML` changes:
	- Fixed `replaceElement` from mixing up elements that start with our desired selector, instead of being only our desired selector

## v1.13.0 August 3, 2012
- `balUtilModules` changes:
	- Added `determineExecPath`, `getNpmPath`, `getTmpPath`, `nodeCommand` and `gitCommand`
	- `initNodeModules` and `initGitRepo` will now get the determined path of the executable if a path isn't passed
- Re-added markdown files to npm distribution as they are required for the npm website

## v1.12.5 July 18, 2012
- `balUtilTypes` changes:
	- Better checks for `isString` and `isNumber` under some environments
- `balUtilFlow` changes:
	- Removed ambigious `clone` function, use `dereference` or `extend` or `deepExtendPlainObjects` instead

## v1.12.4 July 12, 2012
- `balUtilTypes` changes:
	- `isObject` now also checks truthyness to avoid `null` and `undefined` from being objects
	- `isPlainObject` got so good, it can't get better
- `balUtilFlow` changes:
	- added `deepExtendPlainObjects`

## v1.12.3 July 12, 2012
- `balUtilModules` changes:
	- `npmCommand` will now only prefix with the nodePath if the npmPath exists
	- `npmCommand` and `initNodeModules` now use async fs calls instead of sync calls

## v1.12.2 July 12, 2012
- `balUtilFlow` changes:
	- Added `dereference`

## v1.12.1 July 10, 2012
- `balUtilModules` changes:
	- Added `stdin` option to `spawn`

## v1.12.0 July 7, 2012
- Rejigged `balUtilTypes` and now top level
	- Other components now make use of this instead of inline `typeof` and `instanceof` checks
- `balUtilFlow` changes:
	- `isArray` and `toString` moved to `balUtilTypes`

## v1.11.2 July 7, 2012
- `balUtilFlow` changes:
	- Added `clone`
- `balUtilModules` changes:
	- Fixed exists warning on `initNodeModules`
- `balUtilPaths` changes:
	- Added `scanlist`
	- `scandir` changes:
		- If `readFiles` is `true`, then we will return the contents into the list entries as well as the tree entries (we weren't doing this for lists before)

## v1.11.1 July 4, 2012
- `balUtilFlow` changes:
	- `Group` changes:
		- Cleaned up the context handling code
	- `Block` changes:
		- Block constructor as well as `createSubBlock` arguments is now a single `opts` object, acceping the options `name`, `fn`, `parentBlock` and the new `complete`
		- Fixed bug introduced in v1.11.0 causing blocks to complete instantly (instead of once their tasks are finished)

## v1.11.0 July 1, 2012
- Added `balUtilHTML`:
	- `getAttribute(attributes,attribute)`
	- `detectIndentation(source)`
	- `removeIndentation(source)`
	- `replaceElement(source, elementNameMatcher, replaceElementCallback)`
	- `replaceElementAsync(source, elementNameMatcher, replaceElementCallback, next)`
- `balUtilFlow` changes:
	- `wait(delay,fn)` introduced as an alternative to `setTimeout`
	- `Group` changes:
		- `push` and `pushAndRun` signatures are now `([context], task)`
			- `context` is optional, and what we should bind to this
			- it saves us having to often wrap our task pushing into for each scopes
		- task completion callbacks are now optional, if not specified a task will be completed as soon as it finishes executing
- `balUtilEvents`, `balUtilModules` changes:
	- Now make use of the `balUtilFlow.push|pushAndRun` new `context` argument to simplify some loops

## v1.10.3 June 26, 2012
- `balUtilModules` changes:
	- `initNodeModules` will now install modules from cache, unless `force` is true

## v1.10.2 June 26, 2012
- `balUtilModules` changes:
	- `initNodeModules` will now never install modules from cache

## v1.10.1 June 26, 2012
- `balUtilModules` changes:
	- Fixed `npmCommand` under some situations

## v1.10.0 June 26, 2012
- `balUtilModules` changes:
	- Added `spawnMultiple`, `execMultiple`, `gitGitPath`, `getNodePath`, and `npmCommand`
	- `spawn` and `exec` are now only for single commands, use the new `spawnMultiple` and `execMultiple` for multiple commands instead
	- error exit code is now anything that isnt `0`

## v1.9.4 June 22, 2012
- Fixed a problem with large asynchronous groups

## v1.9.3 June 22, 2012
- `balUtilFlow` changes:
	- Added `extractOptsAndCallback` and `extend`

## v1.9.2 June 21, 2012
- `balUtilFlow` changes:
	- Added `fireWithOptionalCallback`, updated groups and emitters to use this

## v1.9.1 June 21, 2012
- `balUtilModules` changes:
	- `initNodeModules` now supports `output` option

## v1.9.0 June 21, 2012
- `balUtilEvents` changes:
	- `EventEmitterEnhanced` changes:
		- `emitSync` and `emitAsync` changes:
			- The next callback is now optional, if it is not detected then we will automatically mark the listener as completed once we have executed it (in other words, if it doesn't have a next callback, then we treat it as a synchronous listener)

## v1.8.8 June 19, 2012
- Fixed a problem with large synchronous groups

## v1.8.7 June 19, 2012
- Defaulted `dependencies` to an empty object, to hopefully fix [npm issue #2540](https://github.com/isaacs/npm/pull/2540)

## v1.8.6 June 19, 2012
- `balUtilEvents` changes:
	- Split `emitSync` and `emitAsync` out of `EventSystem` and into new `EventEmitterEnhanced` that `EventSystem` extends

## v1.8.5 June 11, 2012
- Made next callbacks necessary by default

## v1.8.4 June 11, 2012
- `balUtilModule` changes:
	- `spawn`
		- will now return results in the order of `err`, `stdout`, `stderr`, `code`, `signal`
		- now splits string commands using `/ /`
- `balUtilFlow` changes:
	- `Group` will now only return error as an array if we have more than one error
- Updated for Joe v1.0.0

## v1.8.3 June 9, 2012
- `balUtilCompare` changes:
	- `packageCompare` will now fail gracefully if it receives malformed json

## v1.8.2 June 9, 2012
- Removed request dependency, we now use the native http/https modules

## v1.8.1 June 9, 2012
- Restructured directories
- Removed generated docs, use the wiki instead
- Moved tests from Mocha to [Joe](https://github.com/bevry/joe)
- Travis now tests against node v0.7
- `balUtilPaths` changes:
	- Added `exists` and `existsSync` to normalize node's 0.6 to 0.8 api differences
- Made [request](https://github.com/mikeal/request) an optional dependency

## v1.8.0 June 9, 2012
- Added expiremental `balUtilFlow.Block`
- Possibly some undocumented `balUtilFlow.Group` changes

## v1.7.0 June 4, 2012
- `balUtilFlow` changes:
	- `Group` changes:
		- Constructor now supports `next` and `mode` arguments in any order
		- `clear()` now clears everything
		- Added `hasTasks()`
		- Group completion callback's first argument (the error argument) is now an array of errors (or null if no errors)
		- Added `breakOnError` option (defaults to `true`)
		- Added `autoClear` option to clear once all tasks have run (defualts to `false`)

## v1.6.5 May 30, 2012
- `balUtilFlow` changes:
	- `Group` changes:
		- Reverted the change made in v1.6.4 where errors in callbacks still increment the complete count
			- Instead, you should be using the `hasExited()` instead of `hasCompleted()` which is used to find out if everything passed successfully

## v1.6.4 May 30, 2012
- `balUtilFlow` changes:
	- Added `flow({object,action,[args],[tasks],next})` to simplify calling a series of functions of an object
	- `Group` changes:
		- If complete callback is called with an error, it'll still increment the complete count (it didn't before)
		- Added `hasExited()`
- `balUtilPaths` changes:
	- `writeFile` will now call `ensurePath` before writing the file

## v1.6.3 May 22, 2012
- `balUtilPaths` changes:
	- Fixed a problem introduced with v1.6.0 with `isDirectory` not opening the file before closing it
	- If the number of open files becomes a negative number, we will now throw an error
	- Decreased the max amount of allowed open files from `500` to `100`
	- Increased the wait time for opening a file from `50` to `100`
		- This is now customisable through the global `waitingToOpenFileDelay`

## v1.6.2 May 13, 2012
- Added support for `balUtilFlow` and `balUtilTypes` to be used inside web browsers

## v1.6.1 May 4, 2012
- `balUtilPaths` changes:
	- Fixed `initNodeModules`

## v1.6.0 May 4, 2012
- We now pre-compile our coffee-script
- `balUtilPaths` changes:
	- Added `readFile`, `writeFile`, `mkdir`, `stat`, `readdir`, `unlink`, `rmdir`
	- Renamed `rmdir` to `rmdirDeep`
- `balUtilModules` changes:
	- Removed `initGitSubmodules`, `gitPull`
	- Added `initGitRepo`
	- Rewrote `initNodeModules`

## v1.5.0 April 18, 2012
- `balUtilPaths` changes:
	- `scan` was removed, not sure what it was used for
	- `isDirectory` now returns the `fileStat` argument to the callback
	- `scandir` changes:
		- `ignorePatterns` option when set to true now uses the new `balUtilPaths.commonIgnorePatterns` property
		- fixed error throwing when passed an invalid path
		- now supports a new `stat` option
		- will return the `fileStat` argument to the `fileAction` and `dirAction` callbacks
		- `ignorePatterns` and `ignoreHiddenFiles` will now correctly be passed to child scandir calls
	- `cpdir` and `rpdir` now uses `path.join` and support `ignoreHiddenFiles` and `ignorePatterns`
	- `writetree` now uses `path.join`

## v1.4.3 April 14, 2012
- CoffeeScript dependency is now bundled
- Fixed incorrect octal `0700` should have been `700`

## v1.4.2 April 5, 2012
- Fixed a failing test due to the `bal-util.npm` to `bal-util` rename
- Improvements to `balUtilModules.spawn`
	- will only return an error if the exit code was `1`
	- will also contain the `code` and `signal` with the results
	- `results[x][0]` is now the stderr string, rather than an error object

## v1.4.1 April 5, 2012
- Added `spawn` to `balUtilModules`
- Added `ignoreHiddenFiles` option to `balUtilPaths.scandir`

## v1.4.0 April 2, 2012
- Renamed `balUtilGroups` to `balUtilFlow`
- Added `toString`, `isArray` and `each` to `balUtilFlow`
- Added `rpdir`, `empty`, and `isPathOlderThan` to `balUtilPaths`

## v1.3.0 February 26, 2012
- Added `openFile` and `closeFile` to open and close files safely (always stays below the maximum number of allowed open files)
- Updated all path utilities to use `openFile` and `closeFile`
- Added npm scripts

## v1.2.0 February 14, 2012
- Removed single and multi modes from `exec`, now always returns the same consistent `callback(err,results)` instead

## v1.1.0 February 6, 2012
- Modularized
- Added [docco](http://jashkenas.github.com/docco/) docs

## v1.0 February 5, 2012
- Moved unit tests to [Mocha](http://visionmedia.github.com/mocha/)
	- Offers more flexible unit testing
	- Offers better guarantees that tests actually ran, and that they actually ran correctly
- Added `readPath` and `scantree`
- Added `readFiles` option to `scandir`
- `scandir` now supports arguments in object format
- Removed `parallel`
- Tasks inside groups now are passed `next` as there only argument
- Removed `resolvePath`, `expandPath` and `expandPaths`, they were essentially the same as `path.resolve`
- Most functions will now chain
- `comparePackage` now supports comparing two local, or two remote packages
- Added `gitPull`

## v0.9 January 18, 2012
- Added `exec`, `initNodeModules`, `initGitSubmodules`, `EventSystem.when`
- Added support for no callbacks

## v0.8 November 2, 2011
- Considerable improvements to `scandir`, `cpdir` and `rmdir`
	- Note, passing `false` as the file or dir actions will now skip all of that type. Pass `null` if you do not want that.
	- `dirAction` is now fired before we read the directories children, if you want it to fire after then in the next callback, pass a callback in the 3rd argument. See `rmdir` for an example of this.
- Fixed npm web to url warnings

## v0.7 October 3, 2011
- Added `versionCompare` and `packageCompare` functions
	- Added `request` dependency

## v0.6 September 14, 2011
- Updated `util.Group` to support `async` and `sync` grouping

## v0.4 June 2, 2011
- Added util.type for testing the type of a variable
- Added util.expandPath and util.expandPaths

## v0.3 June 1, 2011
- Added util.Group class for your async needs :)

## v0.2 May 20, 2011
- Added some tests with expresso
- util.scandir now returns err,list,tree
- Added util.writetree

## v0.1 May 18, 2011
- Initial commit
