
<!-- TITLE/ -->

# scandirectory

<!-- /TITLE -->


<!-- BADGES/ -->

[![Build Status](https://img.shields.io/travis/bevry/scandirectory/master.svg)](http://travis-ci.org/bevry/scandirectory "Check this project's build status on TravisCI")
[![NPM version](https://img.shields.io/npm/v/scandirectory.svg)](https://npmjs.org/package/scandirectory "View this project on NPM")
[![NPM downloads](https://img.shields.io/npm/dm/scandirectory.svg)](https://npmjs.org/package/scandirectory "View this project on NPM")
[![Dependency Status](https://img.shields.io/david/bevry/scandirectory.svg)](https://david-dm.org/bevry/scandirectory)
[![Dev Dependency Status](https://img.shields.io/david/dev/bevry/scandirectory.svg)](https://david-dm.org/bevry/scandirectory#info=devDependencies)<br/>
[![Gratipay donate button](https://img.shields.io/gratipay/bevry.svg)](https://www.gratipay.com/bevry/ "Donate weekly to this project using Gratipay")
[![Flattr donate button](https://img.shields.io/badge/flattr-donate-yellow.svg)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](https://img.shields.io/badge/paypal-donate-yellow.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](https://img.shields.io/badge/bitcoin-donate-yellow.svg)](https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a "Donate once-off to this project using BitCoin")
[![Wishlist browse button](https://img.shields.io/badge/wishlist-donate-yellow.svg)](http://amzn.com/w/2F8TXKSNAFG4V "Buy an item on our wishlist for us")

<!-- /BADGES -->


<!-- DESCRIPTION/ -->

Scan a directory recursively with a lot of control and power

<!-- /DESCRIPTION -->


<!-- INSTALL/ -->

## Install

### [NPM](http://npmjs.org/)
- Use: `require('scandirectory')`
- Install: `npm install --save scandirectory`

<!-- /INSTALL -->


## Usage

- `scandir(path, opts, next?)``
- `scandir(opts, next?)``

Options:

- `path`: the path you want to read
- `action`: (default null) can be null or a function to use for both the fileAction and dirAction
- `fileAction`: (default null) can be null or a function to run against each file, in the following format:
	- `fileAction(fileFullPath, fileRelativePath, next(err,skip), fileStat)``
- `dirAction`: (default null) can be null or a function to run against each directory, in the following format:
	- `dirAction(fileFullPath, fileRelativePath, next(err,skip), fileStat)``
- `next`: (default null) can be null or a function to run after the entire directory has been scanned, in the following format:
	- `next(err, list, tree)``
- `stat`: (default null) can be null or a file stat object for the path if we already have one (not actually used yet)
- `recurse`: (default true) can be null or a boolean for whether or not to scan subdirectories too
- `readFiles`: (default false) can be null or a boolean for whether or not we should read the file contents
- `ignorePaths`: (default false) can be null or an array of paths that we should ignore
- `ignoreHiddenFiles`: (default false) can be null or a boolean for if we should ignore files starting with a dot
- `ignoreCommonPatterns`: (default false) can be null or a boolean or a regex
	- if null, becomes true
	- if false, does not do any ignore patterns
	- if true, defaults to bevry/ignorepatterns
	- if regex, uses this value instead of bevry/ignorepatterns
- `ignoreCustomPatterns`: (default false) can be null or a boolean or a regex (same as ignoreCommonPatterns but for ignoreCustomPatterns instead)

Next Callback Arguments:

- `err`: null, or an error that has occured
- `list`: a collection of all the child nodes in a list/object format:
	- `{fileRelativePath: 'dir|file'}`
- `tree`: a colleciton of all the child nodes in a tree format:
	- `{dir: {dir:{}, file1:true} }`
	- if the readFiles option is true, then files will be returned with their contents instead


<!-- CONTRIBUTE/ -->

## Contribute

[Discover how you can contribute by heading on over to the `CONTRIBUTING.md` file.](https://github.com/bevry/scandirectory/blob/master/CONTRIBUTING.md#files)

<!-- /CONTRIBUTE -->


<!-- HISTORY/ -->

## History
[Discover the change history by heading on over to the `HISTORY.md` file.](https://github.com/bevry/scandirectory/blob/master/HISTORY.md#files)

<!-- /HISTORY -->


<!-- BACKERS/ -->

## Backers

### Maintainers

These amazing people are maintaining this project:

- Benjamin Lupton <b@lupton.cc> (https://github.com/balupton)

### Sponsors

No sponsors yet! Will you be the first?

[![Gratipay donate button](https://img.shields.io/gratipay/bevry.svg)](https://www.gratipay.com/bevry/ "Donate weekly to this project using Gratipay")
[![Flattr donate button](https://img.shields.io/badge/flattr-donate-yellow.svg)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](https://img.shields.io/badge/paypal-donate-yellow.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](https://img.shields.io/badge/bitcoin-donate-yellow.svg)](https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a "Donate once-off to this project using BitCoin")
[![Wishlist browse button](https://img.shields.io/badge/wishlist-donate-yellow.svg)](http://amzn.com/w/2F8TXKSNAFG4V "Buy an item on our wishlist for us")

### Contributors

These amazing people have contributed code to this project:

- [Benjamin Lupton](https://github.com/balupton) <b@lupton.cc> — [view contributions](https://github.com/bevry/scandirectory/commits?author=balupton)
- [sfrdmn](https://github.com/sfrdmn) — [view contributions](https://github.com/bevry/scandirectory/commits?author=sfrdmn)

[Become a contributor!](https://github.com/bevry/scandirectory/blob/master/CONTRIBUTING.md#files)

<!-- /BACKERS -->


<!-- LICENSE/ -->

## License

Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT license](http://creativecommons.org/licenses/MIT/)

Copyright &copy; 2011+ Benjamin Lupton <b@lupton.cc> (http://balupton.com)
<br/>Copyright &copy; 2014+ Bevry Pty Ltd <us@bevry.me> (http://bevry.me)

<!-- /LICENSE -->


