# History

## v7.0.1 2017 April 16
- Fixed `fatal: remote origin already exists` on `initGitRepo` when remote already existed, it will now overwrite the remote

## v7.0.0 2017 April 16
- Removed `initOrPullGitRepo` and put its functionality into `initGitRepo` if the appropriate args are provided, also checkout the branch (if provided) before pulling it
  - Thanks to [Nathan Friedly](https://github.com/nfriedly) for his help on [issue #7](https://github.com/bevry/safeps/issues/7) and [pull request #8](https://github.com/bevry/safeps/pull/8)

## v6.4.0 2017 April 16
- Updated base files
- Fix node <0.12 support

## v6.3.0 2016 June 4
- Updated dependencies

## v6.2.0 2016 June 4
- Introduced `determineExecPathSync` which is now used of `opts.sync` is `true` in `determineExecPath`
  - Removes the need for `sync` option in TaskGroup, which has caused too much complexity over the years

## v6.1.0 2016 May 28
- Updated internal conventions
  - Moved from [ESNextGuardian](https://github.com/bevry/esnextguardian) to [Editions](https://github.com/bevry/editions)

## v6.0.2 2015 December 10
- Updated internal conventions

## v6.0.1 2015 September 24
- Updated base files
- Updated dependencies

## v6.0.0 2015 September 7
- Dropped support for node 0.10 and earlier, minimum supported version is now 0.12
	- This is due to the compiled babel code not supporting `for of` loops
- Moved from CoffeeScript to ES6+
- Fixed callback support on `execSync`
- Fixed error handling on `initOrPullGitRepo`

## v5.1.0 2015 April 7
- Added `spawnNodeModule`

## v5.0.0 2015 April 7
- Removed `requireFresh(path)` instead use the [requirefresh](https://npmjs.org/package/requirefresh) package
- Deprecated `path` option on `initGitRepo`, `initOrPullGitRepo`, `initNodeModules` - use `cwd` option instead

## v4.0.0 2015 March 17
- Removed `spawnCommand` and `spawnCommands` use `spawn` and `spawnMultiple` instead

## v3.0.2 2015 March 17
- Will no longer attempt to read `stdout` and `stderr` on spawn if `stdio` option is set (it's not possible)

## v3.0.1 2015 March 17
- Fixed Buffer concatenation error inside spawn

## v3.0.0 2015 March 17
- Backwards Compatibility Breaks:
	- `spawn`'s `stdout` and `stderr` are now Buffers
		- If you're upgrading, all you have to do to get the previous functionality is to do `stdout.toString()`
	- `outputPrefix` value no longer affects `stdout` and `stderr` results (only their output to the terminal)
- Added:
	- `hasSpawnSync`
	- `hasExecSync`
	- `isExecutable(path, opts?, next)`
	- `isExecutableSync(path, opts?, next?)`
	- `spawnSync(command, opts?, next?)`
	- `execSync(command, opts?, next?)`
- Improvements:
	- `exec` now supports `outputPrefix` option
	- The checks to see if an executable path exists and works have been greatly improved and abstracted out from `determineExecPath` into `isExecutable` and `isExecutableSync`
	- `determineExecPath`, `getExecPath`, and `isExecutable` can now operate synchronously with a callback using the `sync: true` option
	- Retrieval and writing to a path cache can now be disabled using the `cache: false` option
- Updated dependencies

## v2.2.13 2015 February 7
- Updated dependencies

## v2.2.12 2014 May 21
- Fix `execMultiple`
- Updated dependencies

## v2.2.11 2014 January 10
- Added `outputPrefix` option for `safeps.spawn`

## v2.2.10 2013 December 27
- Updated dependencies

## v2.2.9 2013 November 6
- Repackaged
- Updated dependencies

## v2.2.8 2013 September 16
- Fixed `Error: A task's completion callback has fired when the task was already in a completed state, this is unexpected` when an error occurs before close within a spawned process

## v2.2.7 2013 August 29
- Updated dependencies

## v2.2.6 2013 June 29
- Added support for `.cmd` aliases on windows to `getPossibleExecPaths`

## v2.2.5 2013 June 29
- Split out possible exec path functionality from `getExecPath` to `getPossibleExecPaths(execName?)`
- Added support for `.bat` aliases on windows to `getPossibleExecPaths`
- More efficient possible exec paths ordering when on windows

## v2.2.4 2013 June 25
- Repackaged

## v2.2.3 2013 June 25
- `spawn` now works when `stdio` is set to `inherit`

## v2.2.2 2013 June 24
- `determineExecPath` now works for processes that do not implement `--version`
- `spawn` now won't crash on `EACCESS` errors

## v2.2.1 2013 June 24
- `determinePossibleExecPath` is now more effecient
- `getGitPath`, `getNodePath`, `getNpmPath` won't added `undefined` paths
- `spawn`
	- now inherits our `process.env` by default, can be changed with `opts.env`
	- now sends `signal` and `code` in the completion callback correctly
	- now works
- `getExecPath`
	- now caches the result
	- won't currupt absolute paths
	- will work with relative paths

## v2.2.0 2013 June 24
- Split from [bal-util](https://github.com/balupton/bal-util) with these additional changes:
	- `spawn` is now safe rather than just `spawnCommand`
	- `spawn` now waits for `close` instead of `exit`
		- Thanks to Johny Jose for [balupton/bal-util#9](https://github.com/balupton/bal-util/pull/9)
	- `getEnvironmentPaths` now uses `require('path').delimiter` for seperation
	- `getStandardExecPaths` now uses `require('path').join` for joining `execName` to a possible path
	- `initGitRepo`, `initOrPullGitRepo` and `initNodeModules` now use `opts.cwd` instead of `opts.path`
