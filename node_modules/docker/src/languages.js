// # Languages
//
// All the languages Docker can parse are in here.
// A language can have the following properties:
//
// * `extensions`: All possible file extensions for the language
// * `executables`: Executables for the language that might be in a shebang
// * `comment`: Delimiter for single-line comments
// * `multiLine`: Start and end delimiters for multi-line comments
// * `commentsIgnore`: Regex for comments that shouldn't be interpreted as descriptive
// * `jsDoc`: whether to try and extract jsDoc-style comment data
// * `literals`: Quoted strings are ignored when looking for comment delimiters. Any extra literals go here
// * `highlightLanguage`: override for language to use with highlight.js

var langs = module.exports = {
  javascript: {
    extensions: [ 'js' ],
    executables: [ 'node' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], commentsIgnore: /^\s*\/\/=/, jsDoc: true,
    literals: [
      [ /\/(?![\*\/])((?:[^\\\/]|(?:\\\\)*?\\[^\\])*?)\//g, '/./' ]
    ]
  },
  coffeescript: {
    extensions: [ 'coffee' ],
    names: [ 'cakefile' ],
    executables: [ 'coffee' ],
    comment: '#', multiLine: [ /^\s*#{3}\s*$/m, /^\s*#{3}\s*$/m ], jsDoc: true,
    literals: [
      [ /\/(?![\*\/])((?:[^\\\/]|(?:\\\\)*?\\[^\\])*?)\//g, '/./' ]
    ]
  },
  livescript: {
    extensions: [ 'ls' ],
    executables: [ 'lsc' ],
    comment: '#', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  ruby: {
    extensions: [ 'rb', 'rbw', 'rake', 'gemspec' ],
    executables: [ 'ruby' ],
    names: [ 'rakefile' ],
    comment: '#', multiLine: [ /\=begin/, /\=end/ ]
  },
  python: {
    extensions: [ 'py' ],
    executables: [ 'python' ],
    comment: '#' // Python has no block commments :-(
  },
  perl: {
    extensions: [ 'pl', 'pm' ],
    executables: [ 'perl' ],
    comment: '#' // Nor (really) does perl.
  },
  c: {
    extensions: [ 'c', 'h' ],
    executables: [ 'gcc' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  cpp: {
    extensions: [ 'cc', 'cpp' ],
    executables: [ 'g++' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  vbnet: {
    extensions: [ 'vb', 'vbs', 'bas' ],
    comment: "'" // No multiline
  },
  'aspx-vb': {
    extensions: [ 'asp', 'aspx', 'asax', 'ascx', 'ashx', 'asmx', 'axd' ],
    comment: "'" // No multiline
  },
  csharp: {
    extensions: [ 'cs' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  'aspx-cs': {
    extensions: [ 'aspx', 'asax', 'ascx', 'ashx', 'asmx', 'axd' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  java: {
    extensions: [ 'java' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  php: {
    extensions: [ 'php', 'php3', 'php4', 'php5' ],
    executables: [ 'php' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  actionscript: {
    extensions: [ 'as' ],
    comment: '//', multiLine: [ /\/\*/, /\*\// ]
  },
  sh: {
    extensions: [ 'sh', 'kst', 'bash' ],
    names: [ '.bashrc', 'bashrc' ],
    executables: [ 'bash', 'sh', 'zsh' ],
    comment: '#'
  },
  yaml: {
    extensions: [ 'yaml', 'yml' ],
    comment: '#'
  },
  markdown: {
    extensions: [ 'md', 'mkd', 'markdown' ],
    type: 'markdown'
  },
  // sass: {
  //   extensions: [ 'sass' ],
  //   comment: '//' //, multiLine: [ /\/\*/, /\*\// ]
  // },
  scss: {
    extensions: [ 'scss' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  makefile: {
    names: [ 'makefile' ],
    comment: '#'
  },
  apache: {
    names: [ '.htaccess', 'apache.conf', 'apache2.conf' ],
    comment: '#'
  },
  jade: {
    extensions: [ 'jade' ],
    comment: '//-?', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  groovy: {
    extensions: [ 'groovy' ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ], jsDoc: true
  },
  gsp: {
    extensions: [ 'gsp' ],
    //comment: '//', gsp only supports multiline comments.
    multiLine: [ /<%--/, /--%>/ ],
    highlightLanguage: 'html'
  },
  stylus: {
    extensions: [ 'styl' ],
    comment: '//', multiLine: [ /\/\*/, /\*\// ]
  },
  css: {
    extensions: [ 'css' ],
    multiLine: [ /\/\*/, /\*\// ],       // for when we detect multi-line comments
    commentStart: '/*', commentEnd: '*/' // for when we add multi-line comments
  },
  less: {
    extensions: [ 'less' ],
    comment: '//', multiLine: [ /\/\*/, /\*\// ]
  },
  html: {
    extensions: [ 'html', 'htm' ],
    multiLine: [ /<!--/, /-->/ ],
    commentStart: '<!--', commentEnd: '-->'
  },
  json: {
    extensions: [ 'json' ],
    names: [ '.eslintrc', '.jshintrc' /* various other .rc's */ ],
    comment: '//', multiLine: [ /\/\*\*?/, /\*\// ]
  }
};

Object.keys(langs).forEach(function(l) {
  langs[l].language = l;
});
