"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _default = /^((~|\.#).*|.*(~|\.swp)|\.(svn|git|hg|DS_Store)|node_modules|CVS|thumbs\.db|desktop\.ini)$/i;
/*
	^(
		# Paths that start with something
		(
			~|          # vim, gedit, etc
			\.#        # emacs
		).*|

		# Paths that end with something
		.*(
			~|          # vim, gedit, etc
			\.swp       # vi
		)|

		# Paths that start with a dot and end with something
		\.(
			svn|
			git|
			hg|
			DS_Store
		)|

		# Paths that match any of the following
		node_modules|
		CVS|
		thumbs\.db|
		desktop\.ini
	)$
*/

exports.default = _default;
module.exports = exports.default;