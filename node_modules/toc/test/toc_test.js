'use strict';

var toc = require('../lib/toc.js');
var fs = require('fs');
var path = require('path');

function fixture(name) {
  var htmlfile = path.join(__dirname, 'fixtures', name + '.html');
  return fs.readFileSync(htmlfile).toString();
}

/*
  ======== A Handy Little Nodeunit Reference ========
  https://github.com/caolan/nodeunit

  Test methods:
    test.expect(numAssertions)
    test.done()
  Test assertions:
    test.ok(value, [message])
    test.equal(actual, expected, [message])
    test.notEqual(actual, expected, [message])
    test.deepEqual(actual, expected, [message])
    test.notDeepEqual(actual, expected, [message])
    test.strictEqual(actual, expected, [message])
    test.notStrictEqual(actual, expected, [message])
    test.throws(block, [error], [message])
    test.doesNotThrow(block, [error], [message])
    test.ifError(value)
*/

exports['untag'] = function(test) {
  test.expect(6);
  test.equal(toc.untag('foo'), 'foo', 'no tags to strip');
  test.equal(toc.untag('<b>foo</b>'), 'foo', 'should strip tags');
  test.equal(toc.untag('<b attribute=whatever>foo</b>'), 'foo', 'should strip tags');
  test.equal(toc.untag('<B>foo</B>'), 'foo', 'should strip tags');
  test.equal(toc.untag('<B><i>foo</i> <span><i>bar<i></span></B>'), 'foo bar', 'should strip tags');
  test.equal(toc.untag('<i>foo&amp;bar</i>'), 'foo&amp;bar', 'should not strip entities');
  test.done();
};

exports['anchor'] = function(test) {
  test.expect(10);
  test.equal(toc.anchor('foo'), 'foo', 'anchor is already lovely.');
  test.equal(toc.anchor('foo    bar     baz'), 'foo-bar-baz', 'spaces get converted to -');
  test.equal(toc.anchor('     foo  bar     '), 'foo-bar', 'leading / trailing spaces get stripped');
  test.equal(toc.anchor('foo----bar-----baz'), 'foo-bar-baz', 'multiple - get converted to -');
  test.equal(toc.anchor('-----foo  bar-----'), 'foo-bar', 'leading / trailing - get stripped');
  test.equal(toc.anchor('i can\'t "go" for that'), 'i-cant-go-for-that', 'quotes get stripped');
  test.equal(toc.anchor('obj / obj.method(this, [that])'), 'obj-obj.method-this-that', 'some other chars get stripped, yay');
  test.equal(toc.anchor('obj.method ( this, [ that ] )'), 'obj.method-this-that', 'remove unnecessary - chars');
  test.equal(toc.anchor('this: that :: the other'), 'this-that-the-other', 'replace : with - chars');
  test.equal(toc.anchor('фøó &amp; βåρ ♥ Бäž'), 'foo-and-bar-love-baz', 'entities and utf characters should be made happy');
  test.done();
};

exports['unique'] = function(test) {
  test.expect(6);
  var names = {};
  test.equal(toc.unique(names, 'foo'), 'foo', 'should be unique.');
  test.equal(toc.unique(names, 'foo'), 'foo-1', 'no longer unique.');
  test.equal(toc.unique(names, 'foo'), 'foo-2', 'no longer unique.');
  test.equal(toc.unique(names, 'bar'), 'bar', 'should be unique.');
  test.equal(toc.unique(names, 'foo-1'), 'foo-1-1', 'not unique.');
  test.equal(toc.unique(names, 'foo-2'), 'foo-2-1', 'not unique.');
  test.done();
};

exports['anchorize'] = {
  'basic': function(test) {
    test.expect(3);
    var src = '<h1><b>H1</b> Header</h1>\n<h2 a=1><b>H2</b> Header</h2>\n<h3 b=2 c=3><b>H3</b> Header</h3>';
    var expected = '<h1><b>H1</b> Header</h1>\n<h2 a=1><a href="#h2-header" name="h2-header"><b>H2</b> Header</a></h2>\n<h3 b=2 c=3><a href="#h3-header" name="h3-header"><b>H3</b> Header</a></h3>';
    var actual = toc.anchorize(src);
    test.equal(actual.src, src, 'should return unprocessed src.');
    test.equal(actual.html, expected, 'should return processed html.');
    test.deepEqual(actual.headers, [
      {
        level: 2,
        attrs: ' a=1',
        header: '<b>H2</b> Header',
        text: 'H2 Header',
        anchor: 'h2-header',
        all: '<h2 a=1><b>H2</b> Header</h2>',
      },
      {
        level: 3,
        attrs: ' b=2 c=3',
        header: '<b>H3</b> Header',
        text: 'H3 Header',
        anchor: 'h3-header',
        all: '<h3 b=2 c=3><b>H3</b> Header</h3>',
      },
    ], 'should return array of header objects.');
    test.done();
  },
  // more tests welcome
};

exports['toc'] = {
  'basic': function(test) {
    test.expect(1);
    var headers = [
      {
        level: 2,
        attrs: ' a=1',
        header: '<b>H2</b> Header',
        text: 'H2 Header',
        anchor: 'h2-header',
        all: '<h2 a=1><b>H2</b> Header</h2>',
      },
      {
        level: 3,
        attrs: ' b=2 c=3',
        header: '<b>H3</b> Header',
        text: 'H3 Header',
        anchor: 'h3-header',
        all: '<h3 b=2 c=3><b>H3</b> Header</h3>',
      },
    ];
    var actual = toc.toc(headers);
    var expected = '<div class="toc"><ul><li><a href="#h2-header">H2 Header</a><ul><li><a href="#h3-header">H3 Header</a></li></ul></li></ul></div>';
    test.equal(actual, expected, 'should return generated TOC html.');
    test.done();
  },
  // more tests welcome
};

exports['process'] = {
  'defaults': function(test) {
    test.expect(1);
    var actual = toc.process(fixture('basic'));
    test.equal(actual, fixture('basic-expected'), 'should process using default options.');
    test.done();
  },
  'unique anchors': function(test) {
    test.expect(1);
    var actual = toc.process(fixture('unique'));
    test.equal(actual, fixture('unique-expected'), 'anchors should be unique.');
    test.done();
  },
  'anchorMin, anchorMax': function(test) {
    test.expect(1);
    var actual = toc.process(fixture('anchorminmax'), {anchorMin: 3, anchorMax: 5});
    test.equal(actual, fixture('anchorminmax-expected'), 'the correct headers should be anchorized.');
    test.done();
  },
  'tocMin, tocMax': function(test) {
    test.expect(1);
    var actual = toc.process(fixture('tocminmax'), {tocMin: 3, tocMax: 5});
    test.equal(actual, fixture('tocminmax-expected'), 'TOC should only contain the correct anchors.');
    test.done();
  },
  // more tests welcome
};
