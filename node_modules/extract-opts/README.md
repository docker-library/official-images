<!-- TITLE/ -->

<h1>Extract Options & Callback</h1>

<!-- /TITLE -->


<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.com/bevry/extract-opts" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/com/bevry/extract-opts/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/extract-opts" title="View this project on NPM"><img src="https://img.shields.io/npm/v/extract-opts.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/extract-opts" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/extract-opts.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/bevry/extract-opts" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/bevry/extract-opts.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/bevry/extract-opts#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/bevry/extract-opts.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-patreon"><a href="https://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-liberapay"><a href="https://liberapay.com/bevry" title="Donate to this project using Liberapay"><img src="https://img.shields.io/badge/liberapay-donate-yellow.svg" alt="Liberapay donate button" /></a></span>
<span class="badge-buymeacoffee"><a href="https://buymeacoffee.com/balupton" title="Donate to this project using Buy Me A Coffee"><img src="https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg" alt="Buy Me A Coffee donate button" /></a></span>
<span class="badge-opencollective"><a href="https://opencollective.com/bevry" title="Donate to this project using Open Collective"><img src="https://img.shields.io/badge/open%20collective-donate-yellow.svg" alt="Open Collective donate button" /></a></span>
<span class="badge-crypto"><a href="https://bevry.me/crypto" title="Donate to this project using Cryptocurrency"><img src="https://img.shields.io/badge/crypto-donate-yellow.svg" alt="crypto donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<!-- /BADGES -->


<!-- DESCRIPTION/ -->

Extract the options and callback from a function's arguments easily

<!-- /DESCRIPTION -->


<!-- INSTALL/ -->

<h2>Install</h2>

<a href="https://npmjs.com" title="npm is a package manager for javascript"><h3>npm</h3></a>
<ul>
<li>Install: <code>npm install --save extract-opts</code></li>
<li>Require: <code>require('extract-opts')</code></li>
</ul>

<a href="https://jspm.io" title="Native ES Modules CDN"><h3>jspm</h3></a>

``` html
<script type="module">
    import * as pkg from '//dev.jspm.io/extract-opts'
</script>
```

<h3><a href="https://editions.bevry.me" title="Editions are the best way to produce and consume packages you care about.">Editions</a></h3>

<p>This package is published with the following editions:</p>

<ul><li><code>extract-opts</code> aliases <code>extract-opts/index.js</code> which uses <a href="https://editions.bevry.me" title="Editions are the best way to produce and consume packages you care about.">Editions</a> to automatically select the correct edition for the consumers environment</li>
<li><code>extract-opts/source/index.js</code> is esnext source code with require for modules</li>
<li><code>extract-opts/edition-browsers/index.js</code> is esnext compiled for browsers with require for modules</li>
<li><code>extract-opts/edition-node-0.10/index.js</code> is esnext compiled for node.js 0.10 with require for modules</li></ul>

<!-- /INSTALL -->


## Usage

``` javascript
var log = console.log.bind(console)
var extractOptsAndCallback = require('extract-opts')

// fs.readFile(filename, [options], callback)
function readFile (filename, opts, next) {
	// Extract options and callback
	var args = extractOptsAndCallback(opts, next)
	opts = args[0]
	next = args[1]

	// Forward for simplicities sake
	require('fs').readFile(filename, opts, next)
}

// Test it
readFile('package.json', log)          // works with no options
readFile('package.json', null, log)    // works with null options
readFile('package.json', {next: log})   // works with just options
```

### Customisation

Extract Options and Callback also supports a third argument.
You can use this third argument to customize the `completionCallbackNames` property that defaults to `['next']`.
This is useful if your completion callback has other names besides `next`.
Allowing you to do the following:

``` javascript
var log = console.log.bind(console)
function extractOptsAndCallback (opts, next, config) {
	if ( config == null )  config = {}
	if ( config.completionCallbackNames == null )  config.completionCallbackNames = ['next', 'complete', 'done']
	return require('extract-opts')(opts, next, config)
}

# The readFile method as before

# Test it
readFile('package.json', {next: log})        # works the standard completion callback name
readFile('package.json', {complete: log})    # works with our custom completion callback name
readFile('package.json', {done: log})        # works with our custom completion callback name
```


<!-- HISTORY/ -->

<h2>History</h2>

<a href="https://github.com/bevry/extract-opts/blob/master/HISTORY.md#files">Discover the release history by heading on over to the <code>HISTORY.md</code> file.</a>

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

<h2>Contribute</h2>

<a href="https://github.com/bevry/extract-opts/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

<h2>Backers</h2>

<h3>Maintainers</h3>

These amazing people are maintaining this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/extract-opts/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/extract-opts">view contributions</a></li></ul>

<h3>Sponsors</h3>

No sponsors yet! Will you be the first?

<span class="badge-patreon"><a href="https://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-liberapay"><a href="https://liberapay.com/bevry" title="Donate to this project using Liberapay"><img src="https://img.shields.io/badge/liberapay-donate-yellow.svg" alt="Liberapay donate button" /></a></span>
<span class="badge-buymeacoffee"><a href="https://buymeacoffee.com/balupton" title="Donate to this project using Buy Me A Coffee"><img src="https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg" alt="Buy Me A Coffee donate button" /></a></span>
<span class="badge-opencollective"><a href="https://opencollective.com/bevry" title="Donate to this project using Open Collective"><img src="https://img.shields.io/badge/open%20collective-donate-yellow.svg" alt="Open Collective donate button" /></a></span>
<span class="badge-crypto"><a href="https://bevry.me/crypto" title="Donate to this project using Cryptocurrency"><img src="https://img.shields.io/badge/crypto-donate-yellow.svg" alt="crypto donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<h3>Contributors</h3>

These amazing people have contributed code to this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/extract-opts/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/extract-opts">view contributions</a></li>
<li><a href="http://seanfridman.com">Sean Fridman</a> — <a href="https://github.com/bevry/extract-opts/commits?author=sfrdmn" title="View the GitHub contributions of Sean Fridman on repository bevry/extract-opts">view contributions</a></li>
<li><a href="http://mattbierner.com">Matt Bierner</a> — <a href="https://github.com/bevry/extract-opts/commits?author=mjbvz" title="View the GitHub contributions of Matt Bierner on repository bevry/extract-opts">view contributions</a></li></ul>

<a href="https://github.com/bevry/extract-opts/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /BACKERS -->


<!-- LICENSE/ -->

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2013+ <a href="http://bevry.me">Bevry Pty Ltd</a></li>
<li>Copyright &copy; 2011+ <a href="http://balupton.com">Benjamin Lupton</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->
