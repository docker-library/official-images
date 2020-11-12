var modes = ["XML", "HTML4", "HTML5"];

modes.reduce(function(prev, name, i){
	var obj = require("./entities/" + name.toLowerCase() + ".json");

	if(prev){
		Object.keys(prev).forEach(function(name){
			obj[name] = prev[name];
		});
	}

	var inverse = getInverse(obj);

	module.exports[name] = {
		strict: getStrictReplacer(obj),
		//there is no non-strict mode for XML
		normal: i === 0 ? null : getReplacer(obj),
		inverse: getInverseReplacer(inverse),
		inverseObj: inverse,
		obj: obj
	};

	return obj;
}, null);

function sortDesc(a, b){
	return a < b ? 1 : -1;
}

function getReplacer(obj){
	var keys = Object.keys(obj).sort(sortDesc);
	var re = keys.join("|")//.replace(/(\w+);\|\1/g, "$1;?");

	// also match hex and char codes
	re += "|#[xX][\\da-fA-F]+;?|#\\d+;?";

	return new RegExp("&(?:" + re + ")", "g");
}

function getStrictReplacer(obj){
	var keys = Object.keys(obj).sort(sortDesc).filter(RegExp.prototype.test, /;$/);
	var re = keys.map(function(name){
		return name.slice(0, -1); //remove trailing semicolon
	}).join("|");

	// also match hex and char codes
	re += "|#[xX][\\da-fA-F]+|#\\d+";

	return new RegExp("&(?:" + re + ");", "g");
}

function getInverse(obj){
	return Object.keys(obj).filter(function(name){
		//prefer identifiers with a semicolon
		return name.substr(-1) === ";" || obj[name + ";"] !== obj[name];
	}).reduce(function(inverse, name){
		inverse[obj[name]] = name;
		return inverse;
	}, {});
}

function getInverseReplacer(inverse){
	return new RegExp("\\" + Object.keys(inverse).sort().join("|\\"), "g");
}
