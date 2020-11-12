
<!-- TITLE/ -->

# Safe FS

<!-- /TITLE -->


<!-- BADGES/ -->

[![Build Status](https://img.shields.io/travis/bevry/safefs/master.svg)](http://travis-ci.org/bevry/safefs "Check this project's build status on TravisCI")
[![NPM version](https://img.shields.io/npm/v/safefs.svg)](https://npmjs.org/package/safefs "View this project on NPM")
[![NPM downloads](https://img.shields.io/npm/dm/safefs.svg)](https://npmjs.org/package/safefs "View this project on NPM")
[![Dependency Status](https://img.shields.io/david/bevry/safefs.svg)](https://david-dm.org/bevry/safefs)
[![Dev Dependency Status](https://img.shields.io/david/dev/bevry/safefs.svg)](https://david-dm.org/bevry/safefs#info=devDependencies)<br/>
[![Gratipay donate button](https://img.shields.io/gratipay/bevry.svg)](https://www.gratipay.com/bevry/ "Donate weekly to this project using Gratipay")
[![Flattr donate button](https://img.shields.io/badge/flattr-donate-yellow.svg)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](https://img.shields.io/badge/paypal-donate-yellow.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](https://img.shields.io/badge/bitcoin-donate-yellow.svg)](https://bevry.me/bitcoin "Donate once-off to this project using BitCoin")
[![Wishlist browse button](https://img.shields.io/badge/wishlist-donate-yellow.svg)](https://bevry.me/wishlist "Buy an item on our wishlist for us")

<!-- /BADGES -->


<!-- DESCRIPTION/ -->

Stop getting EMFILE errors! Open only as many files as the operating system supports.

<!-- /DESCRIPTION -->


<!-- INSTALL/ -->

## Install

### [NPM](http://npmjs.org/)
- Use: `require('safefs')`
- Install: `npm install --save safefs`

<!-- /INSTALL -->


## Usage

``` javascript
var safefs = require('safefs')
```

SafeFS uses [graceful-fs](https://npmjs.org/package/graceful-fs) to wrap all of the standard [file system](http://nodejs.org/docs/latest/api/all.html#all_file_system) methods to avoid EMFILE errors among other problems.

Ontop of graceful-fs, SafeFS also adds additional wrapping on the following methods:

- `writeFile(path, data, options?, next)` - ensure the full path exists before writing to it
- `appendFile(path, data, options?, next)` -  ensure the full path exists before writing to it
- `mkdir(path, mode?, next)` - mode defaults to `0o777 & (~process.umask())`
- `unlink(path, next)` - checks if the file exists before removing it
- `exists(path, next)` - node <v0.6 and >=v0.6 compatibility
- `existsSync(path)` - node <v0.6 and >=v0.6 compatibility

SafeFS also define these additional methods:

- `ensurePath(path, options, next)` - ensure the full path exists, equivalent to unix's `mdir -p path`


<!-- HISTORY/ -->

## History
[Discover the change history by heading on over to the `HISTORY.md` file.](https://github.com/bevry/safefs/blob/master/HISTORY.md#files)

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

## Contribute

[Discover how you can contribute by heading on over to the `CONTRIBUTING.md` file.](https://github.com/bevry/safefs/blob/master/CONTRIBUTING.md#files)

<!-- /CONTRIBUTE -->


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
[![BitCoin donate button](https://img.shields.io/badge/bitcoin-donate-yellow.svg)](https://bevry.me/bitcoin "Donate once-off to this project using BitCoin")
[![Wishlist browse button](https://img.shields.io/badge/wishlist-donate-yellow.svg)](https://bevry.me/wishlist "Buy an item on our wishlist for us")

### Contributors

These amazing people have contributed code to this project:

- [Benjamin Lupton](https://github.com/balupton) <b@lupton.cc> — [view contributions](https://github.com/bevry/safefs/commits?author=balupton)
- [jagill](https://github.com/jagill) — [view contributions](https://github.com/bevry/safefs/commits?author=jagill)
- [sfrdmn](https://github.com/sfrdmn) — [view contributions](https://github.com/bevry/safefs/commits?author=sfrdmn)
- [shama](https://github.com/shama) — [view contributions](https://github.com/bevry/safefs/commits?author=shama)

[Become a contributor!](https://github.com/bevry/safefs/blob/master/CONTRIBUTING.md#files)

<!-- /BACKERS -->


<!-- LICENSE/ -->

## License

Unless stated otherwise all works are:

- Copyright &copy; 2013+ Bevry Pty Ltd <us@bevry.me> (http://bevry.me)
- Copyright &copy; 2011-2012 Benjamin Lupton <b@lupton.cc> (http://balupton.com)

and licensed under:

- The incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://opensource.org/licenses/mit-license.php)

<!-- /LICENSE -->


