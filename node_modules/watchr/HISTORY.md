# History

## v2.6.0 2016 July 15
- Potentially fixed swapfiles breaking watching
	- Thanks to [Josh Levine](https://github.com/jlevine22) for [pull request #76](https://github.com/bevry/watchr/pull/76)

## v2.5.0 2016 July 15
- Updated dependencies
- Updated engines to be node >=0.12 as to align with safefs v4
	- May still work with node 0.10, file a bug report if it doesn't

## v2.4.13 2015 February 7
- Updated dependencies

## v2.4.12 2014 December 17
- Fixed `previousStat` not existing sporadically on delete events
	- Thanks to [Stuart Knightley](https://github.com/Stuk) for [pull request #61](https://github.com/bevry/watchr/pull/61)
- Updated dependencies

## v2.4.11 2014 February 7
- Fixed interval option not beeing passed on to child watchers (regression since v2.4.7)
	- Thanks to [David Byrd](https://github.com/thebyrd) for [pull request #58](https://github.com/bevry/watchr/pull/58)

## v2.4.10 2014 February 7
- Fixed watchr emitting error events incorrectly (regression since v2.4.7)
	- Thanks to [Aaron O'Mullan](https://github.com/AaronO) for [pull request #59](https://github.com/bevry/watchr/pull/59)

## v2.4.9 2014 January 28
- Fixed `"me" is undefined` errors (regression since v2.4.7)

## v2.4.8 2013 December 30
- You can now pass falsey values for`catchupDelay` to disable it

## v2.4.7 2013 December 19
- Fixed: [Text Editor swap files on saving can throw it off](https://github.com/bevry/watchr/issues/33)
- Fixed: [`ENOENT` errors are emitted when dead links a broken symlink is encountered](https://github.com/bevry/watchr/issues/42)
- Updated dependencies

## v2.4.6 2013 November 18
- Updated dependencies

## v2.4.5 2013 November 17
- Updated dependencies

## v2.4.4 2013 October 10
- Added the ability to turn off following links by setting `followLinks` to `false`
	- Thanks to [Fredrik Noren](https://github.com/FredrikNoren) for [pull request #47](https://github.com/bevry/watchr/pull/47)
- Prefer accuracy over speed
	- Use the watch method by default, but don't trust it at all, always double check everything

## v2.4.3 2013 April 10
- More work on swap file handling

## v2.4.2 2013 April 10
- File copies will now trigger events throughout the copy rather than just at the start of the copy
	- Close [issue #35](https://github.com/bevry/watchr/issues/35)

## v2.4.1 2013 April 10
- Fixed bubblr events
- Fixed swap file detection

## v2.4.0 2013 April 5
- Updated dependencies

## v2.3.10 2013 April 1
- Updated dependencies

## v2.3.9 2013 March 17
- Made it so if `duplicateDelay` is falsey we will not do a duplicate check

## v2.3.8 2013 March 17
- Fix `Object #<Object> has no method 'emit'` error
	- Thanks to [Casey Foster](https://github.com/caseywebdev) for [pull request #32](https://github.com/bevry/watchr/pull/32)

## v2.3.7 2013 February 6
- Changed the `preferredMethod` option into `preferredMethods` which accepts an array, defaults to `['watch','watchFile']`
- If the watch action fails at the eve level we will try again with the preferredMethods reversed
	- This solves [issue #31](https://github.com/bevry/watchr/issues/31) where watching of large files would fail
- Changed the `interval` option to default to `5007` (recommended by node) instead of `100` as it was before
	- The `watch` method provides us with immediate notification of changes without utilising polling, however the `watch` method fails for large amounts of files, in which case we will fall back to the `watchFile` method that will use this option, if the option is too small we will be constantly polling the large amount of files for changes using up all the CPU and memory, hence the change into a larger increment which has no CPU and memory impact.

## v2.3.6 2013 February 6
- Fixed fallback when preferredMethod is `watchFile`

## v2.3.5 2013 February 6
- Fixed uncaught exceptions when intialising watchers under certain circumstances

## v2.3.4 2013 February 5
- Better handling and detection of failed watching operations
- Better handling of duplicated events
- Watching is now an atomic operation
	- If watching fails for a descendant, we will close everything related to that watch operation of the eve
- We now prefer the `watch` method over the `watchFile` method
	- This offers great reliability and way less CPU and memory foot print
	- If you still wish to prefer `watchFile`, then set the new configuration option `preferredMethod` to `watchFile`
- Closes [issue #30](https://github.com/bevry/watchr/issues/30) thanks to [Howard Tyson](https://github.com/tizzo)

## v2.3.3 2013 January 8
- Added `outputLog` option
- Added `ignorePaths` option
	- Thanks to [Tane Piper](https://github.com/tanepiper) for [issue #24](https://github.com/bevry/watchr/issues/24)
- Now properly ignores hidden files
	- Thanks to [Ting-yu (Joseph) Chiang](https://github.com/josephj) for [issue #25](https://github.com/bevry/watchr/issues/25) and [Julien M.](https://github.com/julienma) for [issue #28](https://github.com/bevry/watchr/issues/28)
- Added `Watcher::isIgnoredPath` method
- Added tests for ignored and hidden files

## v2.3.2 2013 January 6
- Fixed closing when a child path watcher doesn't exist
	- Closes [pull request #26](https://github.com/bevry/watchr/pull/26) thanks to [Jason Als](https://github.com/jasonals)
- Added close tests

## v2.3.1 2012 December 19
- Fixed a bug with closing directories that have children
	- Thanks to [Casey Foster](https://github.com/caseywebdev) for [issue #23](https://github.com/bevry/watchr/issues/23)

## v2.3.0 2012 December 17
- This is a backwards compatiblity break, however updating is easy, read the notes below.
- We've updated the events we emit to be:
	- `log` for debugging, receives the arguments `logLevel ,args...`
	- `watching` for when watching of the path has completed, receives the arguments `err, isWatching`
	- `change` for listening to change events, receives the arguments `changeType, fullPath, currentStat, previousStat`
	- `error` for gracefully listening to error events, receives the arguments `err`
	- read the README to learn how to bind to these new events
- The `changeType` argument for change listeners has been changed for better clarity and consitency:
	- `change` is now `update`
	- `new` is now `create`
	- `unlink` is now `delete`
- We've updated the return arguments for `require('watchr').watch` for better consitency:
	- if you send the `paths` option, you will receive the arguments `err, results` where `results` is an array of watcher instances
	- if you send the `path` option, you receive the arguments `err, watcherInstance`

## v2.2.1 2012 December 16
- Fixed sub directory scans ignoring our ignore patterns
- Updated dependencies

## v2.2.0 2012 December 15
- We now ignore common ignore patterns by default
-  `ignorePatterns` configuration option renamed to `ignoreCommonPatterns`
-  Added new `ignoreCustomPatterns` configuration option
- Updated dependencies
	-  [bal-util](https://github.com/balupton/bal-util) from 1.13.x to 1.15.x
- Closes [issue #22](https://github.com/bevry/watchr/issues/22) and [issue #21](https://github.com/bevry/watchr/issues/21)
	- Thanks [Andrew Petersen](https://github.com/kirbysayshi), [Sascha Depold](https://github.com/sdepold), [Raynos](https://github.com/Raynos), and [Prajwalit](https://github.com/prajwalit) for your help!

## v2.1.6 2012 November 6
- Added missing `bin` configuration
	- Fixes [#16](https://github.com/bevry/watchr/issues/16) thanks to [pull request #17](https://github.com/bevry/watchr/pull/17) by [Robson Roberto Souza Peixoto](https://github.com/robsonpeixoto)

## v2.1.5 2012 September 29
- Fixed completion callback not firing when trying to watch a path that doesn't exist

## v2.1.4 2012 September 27
- Fixed new listeners not being added for directories that have already been watched
- Fixed completion callbacks happening too soon
- Thanks to [pull request #14](https://github.com/bevry/watchr/pull/14) by [Casey Foster](https://github.com/caseywebdev)

## v2.1.3 2012 August 10
- Re-added markdown files to npm distribution as they are required for the npm website

## v2.1.2 2012 July 7
- Fixed spelling of `persistent`
- Explicitly set the defaults for the options `ignoreHiddenFiles` and `ignorePatterns`

## v2.1.1 2012 July 7
- Added support for `interval` and `persistant` options
- Improved unlink detection
- Optimised unlink handling

## v2.1.0 2012 June 22
- `watchr.watchr` changes
	- now only accepts one argument which is an object
	- added new `paths` property which is an array of multiple paths to watch
	- will only watch paths that actually exist (before it use to throw an error)
- Fixed a few bugs
- Added support for node v0.7/v0.8
- Moved tests from Mocha to [Joe](https://github.com/bevry/joe)

## v2.0.3 2012 April 19
- Fixed a bug with closing watchers
- Now requires pre-compiled code

## v2.0.0 2012 April 19
- Big rewrite
- Got rid of the delay
- Now always fires events
- Watcher instsances inherit from Node's EventEmitter
- Events for `change`, `unlink` and `new`

## v1.0.0 2012 February 11
- Better support for ignoring hidden files
- Improved documentation, readme
- Added `History.md` file
- Added unit tests using [Mocha](http://visionmedia.github.com/mocha/)

## v0.1.0 2012 November 13
- Initial working version
