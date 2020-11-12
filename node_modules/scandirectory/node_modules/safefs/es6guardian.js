// September 5, 2015
// https://github.com/bevry/base
if ( process.env.REQUIRE_ES6 ) {
	module.exports = require('./es6/lib/safefs.js')
}
else if ( !process.versions.v8 || process.versions.v8.split('.')[0] < 4 ) {
	module.exports = require('./es5/lib/safefs.js')
}
else {
	try {
		module.exports = require('./es6/lib/safefs.js')
	}
	catch (e) {
		// console.log('Downgrading from ES6 to ES5 due to:', e.stack)
		module.exports = require('./es5/lib/safefs.js')
	}
}
