
exports.toString = function (obj) {
	var value;
	for(var key in obj) {
		if (obj[key] != null && typeof obj[key] === 'object') {
			value += toString(obj[key]);
		}
		else {
		    value += key + ": " + obj[key] + "\n";
		}
	}
	return value;
}