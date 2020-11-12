#!/usr/bin/env node
//

var fs  = require('fs'),
    path = require('path'),
    http = require('http'),
    BufferStream = require('bufferstream'),

// http://www.ksu.ru/eng/departments/ktk/test/perl/lib/unicode/UCDFF301.html
keys =  ['value', 'name', 'category', 'class',
    'bidirectional_category', 'mapping', 'decimal_digit_value', 'digit_value',
    'numeric_value', 'mirrored', 'unicode_name', 'comment', 'uppercase_mapping',
    'lowercase_mapping', 'titlecase_mapping'],
systemfiles = [
    "UnicodeData.txt"
],

refs = 0;


// based on https://github.com/mathiasbynens/jsesc
function escape(charValue) {
    var hexadecimal = charValue.replace(/^0*/, ''); // is already in hexadecimal
    var longhand = hexadecimal.length > 2;
    return '\\' + (longhand ? 'u' : 'x') +
            ('0000' + hexadecimal).slice(longhand ? -4 : -2);
}

function stringify(key, value) {
    return key + ":" + JSON.stringify(value).replace(/\\\\(u|x)/, "\\$1");
}

function create_index(categories, len) {
    console.log("saving index.js …");
    var filename = path.join(__dirname, "category", "index.js"),
        cat, contents = 'module.exports = {';
    for(var i = 0 ; i < len ; i++) {
        cat = categories[i];
        contents += "\n    " + cat + ": require('./" + cat + "')";
        if ((i + 1) !== len) contents += ',';
    }
    contents += '\n};';
    fs.writeFileSync(filename, contents, {encoding:'utf8'});
}

function newFile(name, callback) {
    var filename = path.join(__dirname, "category", name + ".js"),
        file = fs.createWriteStream(filename, {encoding:'utf8'});
    file.once('close', function () {
        if (!--refs) {
            console.log("done.");
            callback();
        }
    });
    refs++;
    return file;
}

function parser(callback) {
    var data = {},
        buffer = new BufferStream({encoding:'utf8', size:'flexible'}),
        resume = buffer.resume.bind(buffer);

    buffer.split('\n', function (line) {
        var v, c, char = {},
            values = line.toString().split(';');
        for(var i = 0 ; i < 15 ; i++)
            char[keys[i]] = values[i];
        v = parseInt(char.value, 16);
        char.symbol = escape(char.value);
        c = char.category;
        if (!data[c]) {
            data[c] = newFile(c, callback)
                .on('drain', resume)
                .once('open', function () {
                    console.log("saving data as %s.js …", c);
                    if (this.write('module.exports={' + stringify(v, char)))
                        buffer.resume();
                });
            buffer.pause();
        } else if (!data[c].write("," + stringify(v, char))) {
            buffer.pause();
        }
    });


    buffer.on('end', function () {
        var cat, categories = Object.keys(data),
            len = categories.length;
        for(var i = 0 ; i < len ; i++) {
            cat = categories[i];
            data[cat].end("};");
        }
        create_index(categories, len);
    });

    buffer.on('error', function (err) {
        if (typeof err === 'string')
            err = new Error(err);
        throw err;
    });

    return buffer;
}

function read_file(success_cb, error_cb) {
    var systemfile, sysfiles = systemfiles.slice(),
    try_reading = function (success, error) {
        systemfile = sysfiles.shift();
        if (!systemfile) return error_cb();
        console.log("try to read file %s …", systemfile);
        fs.exists(systemfile, function (exists) {
            if (!exists) {
                console.error("%s not found.", systemfile);
                return try_reading(success_cb, error_cb);
            }
            console.log("parsing …");
            fs.createReadStream(systemfile, {encoding:'utf8'}).pipe(parser(success_cb));
        });

    };
    try_reading(success_cb, error_cb);
}

// run
if (!module.parent) { // not required
    read_file(process.exit, process.exit);
} else {
    module.exports = {
        escape:escape,
        stringify:stringify,
        newFile:newFile,
        parser:parser,
        read_file:read_file
    };
}

