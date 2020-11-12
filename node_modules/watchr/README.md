<!-- TITLE/ -->

<h1>watchr</h1>

<!-- /TITLE -->


<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.org/bevry/watchr" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/bevry/watchr/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/watchr" title="View this project on NPM"><img src="https://img.shields.io/npm/v/watchr.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/watchr" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/watchr.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/bevry/watchr" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/bevry/watchr.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/bevry/watchr#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/bevry/watchr.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-slackin"><a href="https://slack.bevry.me" title="Join this project's slack community"><img src="https://slack.bevry.me/badge.svg" alt="Slack community badge" /></a></span>
<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<!-- /BADGES -->


<!-- DESCRIPTION/ -->

Better file system watching for Node.js

<!-- /DESCRIPTION -->


<!-- INSTALL/ -->

<h2>Install</h2>

<a href="https://npmjs.com" title="npm is a package manager for javascript"><h3>NPM</h3></a><ul>
<li>Install: <code>npm install --save watchr</code></li>
<li>Executable: <code>watchr</code></li>
<li>Module: <code>require('watchr')</code></li></ul>

<h3><a href="https://github.com/bevry/editions" title="Editions are the best way to produce and consume packages you care about.">Editions</a></h3>

<p>This package is published with the following editions:</p>

<ul><li><code>watchr/src/lib/getmac.coffee</code> is Source + CoffeeScript + <a href="https://nodejs.org/dist/latest-v5.x/docs/api/modules.html" title="Node/CJS Modules">Require</a></li>
<li><code>watchr/es5/lib/getmac.js</code> is CoffeeScript Compiled JavaScript + ES5 + <a href="https://nodejs.org/dist/latest-v5.x/docs/api/modules.html" title="Node/CJS Modules">Require</a></li></ul>

<!-- /INSTALL -->


Watchr provides a normalised API the file watching APIs of different node versions, nested/recursive file and directory watching, and accurate detailed events for file/directory creations, updates, and deletions.

You install it via `npm install watchr` and use it via `require('watchr').watch(config)`. Available configuration options are:

- `path` a single path to watch
- `paths` an array of paths to watch
- `listener` a single change listener to fire when a change occurs
- `listeners` an array of listeners to fire when a change occurs, overloaded to accept the following values:
	- `changeListener` a single change listener
	- `[changeListener]` an array of change listeners
	- `{eventName: eventListener}` an object keyed with the event names and valued with a single event listener
	- `{eventName: [eventListener]}` an object keyed with the event names and valued with an array of event listeners
- `next` (optional, defaults to `null`) a completion callback to fire once the watchers have been setup, arguments are:
	- when using the `path` configuration option: `err, watcherInstance`
	- when using the `paths` configuration option: `err, [watcherInstance,...]`
- `stat` (optional, defaults to `null`) a file stat object to use for the path, instead of fetching a new one
- `interval` (optional, defaults to `5007`) for systems that poll to detect file changes, how often should it poll in millseconds
- `persistent` (optional, defaults to `true`) whether or not we should keep the node process alive for as long as files are still being watched
- `catchupDelay` (optional, defaults to `2000`) because swap files delete the original file, then rename a temporary file over-top of the original file, to ensure the change is reported correctly we must have a delay in place that waits until all change events for that file have finished, before starting the detection of what changed
- `preferredMethods` (optional, defaults to `['watch','watchFile']`) which order should we prefer our watching methods to be tried?
- `followLinks` (optional, defaults to `true`) follow symlinks, i.e. use stat rather than lstat
- `ignorePaths` (optional, defaults to `false`) an array of full paths to ignore
- `ignoreHiddenFiles` (optional, defaults to `false`) whether or not to ignored files which filename starts with a `.`
- `ignoreCommonPatterns` (optional, defaults to `true`) whether or not to ignore common undesirable file patterns (e.g. `.svn`, `.git`, `.DS_Store`, `thumbs.db`, etc)
- `ignoreCustomPatterns` (optional, defaults to `null`) any custom ignore patterns that you would also like to ignore along with the common patterns

The following events are available to your via the listeners:

- `log` for debugging, receives the arguments `logLevel ,args...`
- `error` for gracefully listening to error events, receives the arguments `err`
	- you should always have an error listener, otherwise node.js's behavior is to throw the error and possibly crash your application, see [#40](https://github.com/bevry/watchr/issues/40)
- `watching` for when watching of the path has completed, receives the arguments `err, isWatching`
- `change` for listening to change events, receives the arguments `changeType, fullPath, currentStat, previousStat`, received arguments will be:
	- for updated files: `'update', fullPath, currentStat, previousStat`
	- for created files: `'create', fullPath, currentStat, null`
	- for deleted files: `'delete', fullPath, null, previousStat`


To wrap it all together, it would look like this:

``` javascript
// Require
var watchr = require('watchr')

// Watch a directory or file
console.log('Watch our paths')
watchr.watch({
	paths: ['path1', 'path2', 'path3'],
	listeners: {
		log: function (logLevel) {
			console.log('a log message occured:', arguments)
		},
		error: function (err) {
			console.log('an error occured:', err)
		},
		watching: function (err, watcherInstance, isWatching){
			if (err) {
				console.log("watching the path " + watcherInstance.path + " failed with error", err)
			} else {
				console.log("watching the path " + watcherInstance.path + " completed")
			}
		},
		change: function(changeType, filePath, fileCurrentStat, filePreviousStat){
			console.log('a change event occured:', arguments)
		}
	},
	next: function(err, watchers){
		if (err) {
			return console.log("watching everything failed with error", err)
		} else {
			console.log('watching everything completed', watchers)
		}

		// Close watchers after 60 seconds
		setTimeout(function () {
			console.log('Stop watching our paths')
			for ( var i = 0; i < watchers.length; i++ ) {
				watchers[i].close()
			}
		}, 60 * 1000)
	}
})
```

You can test the above code snippet by running the following:

```
npm install -g watchr
watchr
```


<!-- HISTORY/ -->

<h2>History</h2>

<a href="https://github.com/bevry/watchr/blob/master/HISTORY.md#files">Discover the release history by heading on over to the <code>HISTORY.md</code> file.</a>

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

<h2>Contribute</h2>

<a href="https://github.com/bevry/watchr/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

<h2>Backers</h2>

<h3>Maintainers</h3>

These amazing people are maintaining this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/watchr/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/watchr">view contributions</a></li></ul>

<h3>Sponsors</h3>

No sponsors yet! Will you be the first?

<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<h3>Contributors</h3>

These amazing people have contributed code to this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/watchr/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/watchr">view contributions</a></li>
<li><a href="http://www.gitbook.com">Aaron O'Mullan</a> — <a href="https://github.com/bevry/watchr/commits?author=AaronO" title="View the GitHub contributions of Aaron O'Mullan on repository bevry/watchr">view contributions</a></li>
<li><a href="monkeyandcrow.com">Adam Sanderson</a> — <a href="https://github.com/bevry/watchr/commits?author=adamsanderson" title="View the GitHub contributions of Adam Sanderson on repository bevry/watchr">view contributions</a></li>
<li><a href="http://ca.sey.me">Casey Foster</a> — <a href="https://github.com/bevry/watchr/commits?author=caseywebdev" title="View the GitHub contributions of Casey Foster on repository bevry/watchr">view contributions</a></li>
<li><a href="https://github.com/FredrikNoren">Fredrik Norén</a> — <a href="https://github.com/bevry/watchr/commits?author=FredrikNoren" title="View the GitHub contributions of Fredrik Norén on repository bevry/watchr">view contributions</a></li>
<li><a href="https://github.com/robsonpeixoto">Robson Roberto Souza Peixoto</a> — <a href="https://github.com/bevry/watchr/commits?author=robsonpeixoto" title="View the GitHub contributions of Robson Roberto Souza Peixoto on repository bevry/watchr">view contributions</a></li>
<li><a href="http://stuartk.com/">Stuart Knightley</a> — <a href="https://github.com/bevry/watchr/commits?author=Stuk" title="View the GitHub contributions of Stuart Knightley on repository bevry/watchr">view contributions</a></li>
<li><a href="http://digitalocean.com">David Byrd</a> — <a href="https://github.com/bevry/watchr/commits?author=thebyrd" title="View the GitHub contributions of David Byrd on repository bevry/watchr">view contributions</a></li></ul>

<a href="https://github.com/bevry/watchr/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /BACKERS -->


<!-- LICENSE/ -->

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2012+ <a href="http://bevry.me">Bevry Pty Ltd</a></li>
<li>Copyright &copy; 2011 <a href="http://balupton.com">Benjamin Lupton</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->
