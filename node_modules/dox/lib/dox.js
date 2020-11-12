/*!
 * Module dependencies.
 */

var markdown = require('marked');

var renderer = new markdown.Renderer();

renderer.heading = function (text, level) {
  return '<h' + level + '>' + text + '</h' + level + '>\n';
};

renderer.paragraph = function (text) {
  return '<p>' + text + '</p>';
};

renderer.br = function () {
  return '<br />';
};

var markedOptions = {
  renderer: renderer
, gfm: true
, tables: true
, breaks: true
, pedantic: false
, sanitize: false
, smartLists: true
, smartypants: false
};

markdown.setOptions(markedOptions);

/**
 * Expose api.
 */

exports.api = require('./api');

/**
 * Parse comments in the given string of `js`.
 *
 * @param {String} js
 * @param {Object} options
 * @return {Array}
 * @see exports.parseComment
 * @api public
 */

exports.parseComments = function(js, options){
  options = options || {};
  js = js.replace(/\r\n/gm, '\n');

  var comments = []
    , skipSingleStar = options.skipSingleStar
    , comment
    , buf = ''
    , ignore
    , withinMultiline = false
    , withinSingle = false
    , withinString = false
    , code
    , linterPrefixes = options.skipPrefixes || ['jslint', 'jshint', 'eshint']
    , skipPattern = new RegExp('^' + (options.raw ? '' : '<p>') + '('+ linterPrefixes.join('|') + ')')
    , lineNum = 1
    , lineNumStarting = 1
    , parentContext
    , withinEscapeChar
    , currentStringQuoteChar;


  for (var i = 0, len = js.length; i < len; ++i) {
    withinEscapeChar = withinString && !withinEscapeChar && js[i - 1] == '\\';

    // start comment
    if (!withinMultiline && !withinSingle && !withinString &&
        '/' == js[i] && '*' == js[i+1] && (!skipSingleStar || js[i+2] == '*')) {
      lineNumStarting = lineNum;
      // code following the last comment
      if (buf.trim().length) {
        comment = comments[comments.length - 1];
        if(comment) {
          // Adjust codeStart for any vertical space between comment and code
          comment.codeStart += buf.match(/^(\s*)/)[0].split('\n').length - 1;
          comment.code = code = exports.trimIndentation(buf).trim();
          comment.ctx = exports.parseCodeContext(code, parentContext);

          if (comment.isConstructor && comment.ctx){
              comment.ctx.type = "constructor";
          }

          // starting a new namespace
          if (comment.ctx && (comment.ctx.type === 'prototype' || comment.ctx.type === 'class')){
            parentContext = comment.ctx;
          }
          // reasons to clear the namespace
          // new property/method in a different constructor
          else if (!parentContext || !comment.ctx || !comment.ctx.constructor || !parentContext.constructor || parentContext.constructor !== comment.ctx.constructor){
            parentContext = null;
          }
        }
        buf = '';
      }
      i += 2;
      withinMultiline = true;
      ignore = '!' == js[i];

      // if the current character isn't whitespace and isn't an ignored comment,
      // back up one character so we don't clip the contents
      if (' ' !== js[i] && '\n' !== js[i] && '\t' !== js[i] && '!' !== js[i]) i--;

    // end comment
    } else if (withinMultiline && !withinSingle && '*' == js[i] && '/' == js[i+1]) {
      i += 2;
      buf = buf.replace(/^[ \t]*\* ?/gm, '');
      comment = exports.parseComment(buf, options);
      comment.ignore = ignore;
      comment.line = lineNumStarting;
      comment.codeStart = lineNum + 1;
      if (!comment.description.full.match(skipPattern)) {
        comments.push(comment);
      }
      withinMultiline = ignore = false;
      buf = '';
    } else if (!withinSingle && !withinMultiline && !withinString && '/' == js[i] && '/' == js[i+1]) {
      withinSingle = true;
      buf += js[i];
    } else if (withinSingle && !withinMultiline && '\n' == js[i]) {
      withinSingle = false;
      buf += js[i];
    } else if (!withinSingle && !withinMultiline && !withinEscapeChar && ('\'' == js[i] || '"' == js[i])) {
      if(withinString) {
        if(js[i] == currentStringQuoteChar) {
          withinString = false;
        }
      } else {
        withinString = true;
        currentStringQuoteChar = js[i];
      }

      buf += js[i];
    } else {
      buf += js[i];
    }

    if('\n' == js[i]) {
      lineNum++;
    }

  }

  if (comments.length === 0) {
    comments.push({
      tags: [],
      description: {full: '', summary: '', body: ''},
      isPrivate: false,
      isConstructor: false,
      line: lineNumStarting
    });
  }

  // trailing code
  if (buf.trim().length) {
    comment = comments[comments.length - 1];
    // Adjust codeStart for any vertical space between comment and code
    comment.codeStart += buf.match(/^(\s*)/)[0].split('\n').length - 1;
    comment.code = code = exports.trimIndentation(buf).trim();
    comment.ctx = exports.parseCodeContext(code, parentContext);
  }

  return comments;
};

/**
 * Removes excess indentation from string of code.
 *
 * @param {String} str
 * @return {String}
 * @api public
 */

exports.trimIndentation = function (str) {
  // Find indentation from first line of code.
  var indent = str.match(/(?:^|\n)([ \t]*)[^\s]/);
  if (indent) {
    // Replace indentation on all lines.
    str = str.replace(new RegExp('(^|\n)' + indent[1], 'g'), '$1');
  }
  return str;
};

/**
 * Parse the given comment `str`.
 *
 * The comment object returned contains the following
 *
 *  - `tags`  array of tag objects
 *  - `description` the first line of the comment
 *  - `body` lines following the description
 *  - `content` both the description and the body
 *  - `isPrivate` true when "@api private" is used
 *
 * @param {String} str
 * @param {Object} options
 * @return {Object}
 * @see exports.parseTag
 * @api public
 */

exports.parseComment = function(str, options) {
  str = str.trim();
  options = options || {};

  var comment = { tags: [] }
    , raw = options.raw
    , description = {}
    , tags = str.split(/\n\s*@/);

  // A comment has no description
  if (tags[0].charAt(0) === '@') {
    tags.unshift('');
  }

  // parse comment body
  description.full = tags[0];
  description.summary = description.full.split('\n\n')[0];
  description.body = description.full.split('\n\n').slice(1).join('\n\n');
  comment.description = description;

  // parse tags
  if (tags.length) {
    comment.tags = tags.slice(1).map(exports.parseTag);
    comment.isPrivate = comment.tags.some(function(tag){
      return 'private' == tag.visibility;
    });
    comment.isConstructor = comment.tags.some(function(tag){
      return 'constructor' == tag.type || 'augments' == tag.type;
    });
    comment.isClass = comment.tags.some(function(tag){
      return 'class' == tag.type;
    });
    comment.isEvent = comment.tags.some(function(tag){
      return 'event' == tag.type;
    });

    if (!description.full || !description.full.trim()) {
      comment.tags.some(function(tag){
        if ('description' == tag.type) {
          description.full = tag.full;
          description.summary = tag.summary;
          description.body = tag.body;
          return true;
        }
      });
    }
  }

  // markdown
  if (!raw) {
    description.full = markdown(description.full);
    description.summary = markdown(description.summary);
    description.body = markdown(description.body);
    comment.tags.forEach(function (tag) {
      if (tag.description) tag.description = markdown(tag.description);
      else tag.html = markdown(tag.string);
    });
  }

  return comment;
};

//TODO: Find a smarter way to do this
/**
 * Extracts different parts of a tag by splitting string into pieces separated by whitespace. If the white spaces are
 * somewhere between curly braces (which is used to indicate param/return type in JSDoc) they will not be used to split
 * the string. This allows to specify jsdoc tags without the need to eliminate all white spaces i.e. {number | string}
 *
 * @param str The tag line as a string that needs to be split into parts
 * @returns {Array.<string>} An array of strings containing the parts
 */

exports.extractTagParts = function(str) {
  var level = 0,
    extract = '',
    split = [];

  str.split('').forEach(function(c) {
    if(c.match(/\s/) && level === 0) {
      split.push(extract);
      extract = '';
    } else {
      if(c === '{') {
        level++;
      } else if (c === '}') {
        level--;
      }

      extract += c;
    }
  });

  split.push(extract);
  return split.filter(function(str) {
    return str.length > 0;
  });
};


/**
 * Parse tag string "@param {Array} name description" etc.
 *
 * @param {String}
 * @return {Object}
 * @api public
 */

exports.parseTag = function(str) {
  var tag = {}
    , lines = str.split('\n')
    , parts = exports.extractTagParts(lines[0])
    , type = tag.type = parts.shift().replace('@', '')
    , matchType = new RegExp('^@?' + type + ' *')
    , matchTypeStr = /^\{.+\}$/;

  tag.string = str.replace(matchType, '');

  if (lines.length > 1) {
    parts.push(lines.slice(1).join('\n'));
  }

  switch (type) {
    case 'property':
    case 'template':
    case 'param':
      var typeString = matchTypeStr.test(parts[0]) ? parts.shift() : "";
      tag.name = parts.shift() || '';
      tag.description = parts.join(' ');
      exports.parseTagTypes(typeString, tag);
      break;
    case 'define':
    case 'return':
    case 'returns':
      var typeString = matchTypeStr.test(parts[0]) ? parts.shift() : "";
      exports.parseTagTypes(typeString, tag);
      tag.description = parts.join(' ');
      break;
    case 'see':
      if (~str.indexOf('http')) {
        tag.title = parts.length > 1
          ? parts.shift()
          : '';
        tag.url = parts.join(' ');
      } else {
        tag.local = parts.join(' ');
      }
      break;
    case 'api':
      tag.visibility = parts.shift();
      break;
    case 'public':
    case 'private':
    case 'protected':
      tag.visibility = type;
      break;
    case 'enum':
    case 'typedef':
    case 'type':
      exports.parseTagTypes(parts.shift(), tag);
      break;
    case 'lends':
    case 'memberOf':
      tag.parent = parts.shift();
      break;
    case 'extends':
    case 'implements':
    case 'augments':
      tag.otherClass = parts.shift();
      break;
    case 'borrows':
      tag.otherMemberName = parts.join(' ').split(' as ')[0];
      tag.thisMemberName = parts.join(' ').split(' as ')[1];
      break;
    case 'throws':
      var typeString = matchTypeStr.test(parts[0]) ? parts.shift() : "";
      tag.types = exports.parseTagTypes(typeString);
      tag.description = parts.join(' ');
      break;
    case 'description':
      tag.full = parts.join(' ').trim();
      tag.summary = tag.full.split('\n\n')[0];
      tag.body = tag.full.split('\n\n').slice(1).join('\n\n');
      break;
    default:
      tag.string = parts.join(' ').replace(/\s+$/, '');
      break;
  }

  return tag;
};

/**
 * Parse tag type string "{Array|Object}" etc.
 * This function also supports complex type descriptors like in jsDoc or even the enhanced syntax used by the
 * [google closure compiler](https://developers.google.com/closure/compiler/docs/js-for-compiler#types)
 *
 * The resulting array from the type descriptor `{number|string|{name:string,age:number|date}}` would look like this:
 *
 *     [
 *       'number',
 *       'string',
 *       {
 *         age: ['number', 'date'],
 *         name: ['string']
 *       }
 *     ]
 *
 * @param {String} str
 * @return {Array}
 * @api public
 */

exports.parseTagTypes = function(str, tag) {
  if (!str) {
    if(tag) {
      tag.types = [];
      tag.typesDescription = "";
      tag.optional = tag.nullable = tag.nonNullable = tag.variable = false;
    }
    return [];
  }
  var Parser = require('jsdoctypeparser').Parser;
  var Builder = require('jsdoctypeparser').Builder;
  var result = new Parser().parse(str.substr(1, str.length - 2));

  var types = (function transform(type) {
    if(type instanceof Builder.TypeUnion) {
      return type.types.map(transform);
    } else if(type instanceof Builder.TypeName) {
      return type.name;
    } else if(type instanceof Builder.RecordType) {
      return type.entries.reduce(function(obj, entry) {
        obj[entry.name] = transform(entry.typeUnion);
        return obj;
      }, {});
    } else {
      return type.toString();
    }
  }(result));

  if(tag) {
    tag.types = types;
    tag.typesDescription = result.toHtml();
    tag.optional = (tag.name && tag.name.slice(0,1) === '[') || result.optional;
    tag.nullable = result.nullable;
    tag.nonNullable = result.nonNullable;
    tag.variable = result.variable;
  }

  return types;
};

/**
 * Determine if a parameter is optional.
 *
 * Examples:
 * JSDoc: {Type} [name]
 * Google: {Type=} name
 * TypeScript: {Type?} name
 *
 * @param {Object} tag
 * @return {Boolean}
 * @api public
 */

exports.parseParamOptional = function(tag) {
  var lastTypeChar = tag.types.slice(-1)[0].slice(-1);
  return tag.name.slice(0,1) === '[' || lastTypeChar === '=' || lastTypeChar === '?';
};

/**
 * Parse the context from the given `str` of js.
 *
 * This method attempts to discover the context
 * for the comment based on it's code. Currently
 * supports:
 *
 *   - classes
 *   - class constructors
 *   - class methods
 *   - function statements
 *   - function expressions
 *   - prototype methods
 *   - prototype properties
 *   - methods
 *   - properties
 *   - declarations
 *
 * @param {String} str
 * @param {Object=} parentContext An indication if we are already in something. Like a namespace or an inline declaration.
 * @return {Object}
 * @api public
 */

exports.parseCodeContext = function(str, parentContext) {
  parentContext = parentContext || {};

  var ctx;

  // loop through all context matchers, returning the first successful match
  return exports.contextPatternMatchers.some(function (matcher) {
    return ctx = matcher(str, parentContext);
  }) && ctx;
};

exports.contextPatternMatchers = [

  function (str) {
    // class, possibly exported by name or as a default
    if (/^\s*(export(\s+default)?\s+)?class\s+([\w$]+)(\s+extends\s+([\w$.]+(?:\(.*\))?))?\s*{/.exec(str)) {
      return {
          type: 'class'
        , constructor: RegExp.$3
        , cons: RegExp.$3
        , name: RegExp.$3
        , extends: RegExp.$5
        , string: 'new ' + RegExp.$3 + '()'
      };
    }
  },

  function (str, parentContext) {
    // class constructor
    if (/^\s*constructor\s*\(/.exec(str)) {
      return {
        type: 'constructor'
        , constructor: parentContext.name
        , cons: parentContext.name
        , name: 'constructor'
        , string: (parentContext && parentContext.name && parentContext.name + '.prototype.' || '') + 'constructor()'
      };
    // class method
    }
  },

  function (str, parentContext) {
    if (/^\s*(static)?\s*(\*)?\s*([\w$]+|\[.*\])\s*\(/.exec(str)) {
      return {
        type: 'method'
        , constructor: parentContext.name
        , cons: parentContext.name
        , name: RegExp.$2 + RegExp.$3
        , string: (parentContext && parentContext.name && parentContext.name + (RegExp.$1 ? '.' : '.prototype.') || '') + RegExp.$2 + RegExp.$3 + '()'
      };
    // named function statement, possibly exported by name or as a default
    }
  },

  function (str) {
    if (/^\s*(export(\s+default)?\s+)?function\s+([\w$]+)\s*\(/.exec(str)) {
      return {
          type: 'function'
        , name: RegExp.$3
        , string: RegExp.$3 + '()'
      };
    }
  },

  function (str) {
    // anonymous function expression exported as a default
    if (/^\s*export\s+default\s+function\s*\(/.exec(str)) {
      return {
          type: 'function'
        , name: RegExp.$1 // undefined
        , string: RegExp.$1 + '()'
      };
    }
  },

  function (str) {
    // function expression
    if (/^return\s+function(?:\s+([\w$]+))?\s*\(/.exec(str)) {
      return {
          type: 'function'
        , name: RegExp.$1
        , string: RegExp.$1 + '()'
      };
    }
  },

  function (str) {
    // function expression
    if (/^\s*(?:const|let|var)\s+([\w$]+)\s*=\s*function/.exec(str)) {
      return {
          type: 'function'
        , name: RegExp.$1
        , string: RegExp.$1 + '()'
      };
    }
  },

  function (str, parentContext) {
    // prototype method
    if (/^\s*([\w$.]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*=\s*function/.exec(str)) {
      return {
          type: 'method'
        , constructor: RegExp.$1
        , cons: RegExp.$1
        , name: RegExp.$2
        , string: RegExp.$1 + '.prototype.' + RegExp.$2 + '()'
      };
    }
  },

  function (str) {
    // prototype property
    if (/^\s*([\w$.]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*=\s*([^\n;]+)/.exec(str)) {
      return {
          type: 'property'
        , constructor: RegExp.$1
        , cons: RegExp.$1
        , name: RegExp.$2
        , value: RegExp.$3.trim()
        , string: RegExp.$1 + '.prototype.' + RegExp.$2
      };
    }
  },

  function (str) {
    // prototype property without assignment
    if (/^\s*([\w$]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*/.exec(str)) {
      return {
          type: 'property'
        , constructor: RegExp.$1
        , cons: RegExp.$1
        , name: RegExp.$2
        , string: RegExp.$1 + '.prototype.' + RegExp.$2
      };
    }
  },

  function (str) {
    // inline prototype
    if (/^\s*([\w$.]+)\s*\.\s*prototype\s*=\s*{/.exec(str)) {
      return {
        type: 'prototype'
        , constructor: RegExp.$1
        , cons: RegExp.$1
        , name: RegExp.$1
        , string: RegExp.$1 + '.prototype'
      };
    }
  },

  function (str, parentContext) {
    // inline method
    if (/^\s*([\w$.]+)\s*:\s*function/.exec(str)) {
      return {
        type: 'method'
        , constructor: parentContext.name
        , cons: parentContext.name
        , name: RegExp.$1
        , string: (parentContext && parentContext.name && parentContext.name + '.prototype.' || '') + RegExp.$1 + '()'
      };
    }
  },

  function (str, parentContext) {
    // inline property
    if (/^\s*([\w$.]+)\s*:\s*([^\n;]+)/.exec(str)) {
      return {
        type: 'property'
        , constructor: parentContext.name
        , cons: parentContext.name
        , name: RegExp.$1
        , value: RegExp.$2.trim()
        , string: (parentContext && parentContext.name && parentContext.name + '.' || '') + RegExp.$1
      };
    }
  },

  function (str, parentContext) {
    // inline getter/setter
    if (/^\s*(get|set)\s*([\w$.]+)\s*\(/.exec(str)) {
      return {
        type: 'property'
        , constructor: parentContext.name
        , cons: parentContext.name
        , name: RegExp.$2
        , string: (parentContext && parentContext.name && parentContext.name + '.prototype.' || '') + RegExp.$2
      };
    }
  },

  function (str) {
    // method
    if (/^\s*([\w$.]+)\s*\.\s*([\w$]+)\s*=\s*function/.exec(str)) {
      return {
          type: 'method'
        , receiver: RegExp.$1
        , name: RegExp.$2
        , string: RegExp.$1 + '.' + RegExp.$2 + '()'
      };
    }
  },

  function (str) {
    // property
    if (/^\s*([\w$.]+)\s*\.\s*([\w$]+)\s*=\s*([^\n;]+)/.exec(str)) {
      return {
          type: 'property'
        , receiver: RegExp.$1
        , name: RegExp.$2
        , value: RegExp.$3.trim()
        , string: RegExp.$1 + '.' + RegExp.$2
      };
    }
  },

  function (str) {
    // declaration
    if (/^\s*(?:const|let|var)\s+([\w$]+)\s*=\s*([^\n;]+)/.exec(str)) {
      return {
          type: 'declaration'
        , name: RegExp.$1
        , value: RegExp.$2.trim()
        , string: RegExp.$1
      };
    }
  }
];

exports.setMarkedOptions = function(opts) {
  markdown.setOptions(opts);
};
