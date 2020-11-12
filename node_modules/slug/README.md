# [slug](https://github.com/dodo/node-slug)

slugifies every string, even when it contains unicode!

Make strings url-safe.

- Comprehensive tests
- No dependencies (except the unicode table)
- Not in coffee-script (except the tests lol)
- Coerces foreign symbols to their english equivalent
- Works in browser (window.slug) and AMD/CommonJS-flavoured module loaders (except the unicode symbols unless you use browserify but who wants to download a ~2mb js file, right?)

```
npm install slug
```

## example

```bash
master//node-slug » node
> slug = require ('./slug')
> slug('i ♥ unicode')
 'i-love-unicode'
> slug('i ♥ unicode', '_') # If you prefer something else then `-` as seperator
 'i_love_unicode'
> slug.charmap['♥'] = 'freaking love' # change default charmap or use option {charmap:{…}} as 2. argument
> slug('I ♥ UNICODE').toLowerCase() # If you prefer lower case
 'i-freaking-love-unicode'
> slug('unicode ♥ is ☢') # yes!
 'unicode-love-is-radioactive'
```

## options

```javascript
// options is either object or replacement (sets options.replacement)
slug('string', [{options} || 'replacement']);
```

```javascript
slug.defaults = {
    replacement: '-',      // replace spaces with replacement
    symbols: true,         // replace unicode symbols or not
    charmap: slug.charmap, // replace special characters
};
```

[![Build Status](https://secure.travis-ci.org/dodo/node-slug.png)](http://travis-ci.org/dodo/node-slug)

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/dodo/node-slug/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

