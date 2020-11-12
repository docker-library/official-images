var path = require('path');
var assert = require('assert');
var categories = [
    "Cc Cf Co Cs",
    "Ll Lm Lo Lt Lu",
    "Mc Me Mn",
    "Nd Nl No",
    "Pc Pd Pe Pf Pi Po Ps",
    "Sc Sk Sm So",
    "Zl Zp Zs",
].join(' ').split(' ');


categories.forEach(function (cat) {
    assert.doesNotThrow(function () {
        process.stdout.write("   unicode/category/"+cat+"\r ");
        // test if we can load it
        require('./category/'+cat);
        // clean up
        delete require.cache[path.join(__dirname, 'category', cat+".js")];
        // ✓
        process.stdout.write("\x1B[32m✓\x1B[39m unicode/category/"+cat+"\n");
    }, function(err){if(err){console.error(err);return 1}}, "failed to load "+cat+".js");
});
console.log("done.");
