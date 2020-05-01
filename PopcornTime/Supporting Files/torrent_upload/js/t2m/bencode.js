


// Module for encoding/decoding Bencoded data
var Bencode = (function () {
	"use strict";

	// Encoding functions
	var encode = function (value) {
		// Type
		var t = typeof(value);

		// Number
		if (t == "number") return encode_int(Math.floor(value));
		// String
		if (t == "string") return encode_string(value);
		// Array
		if (Array.isArray(value)) return encode_list(value);
		// Dict
		return encode_dict(value);
	};

	var encode_int = function (value) {
		return "i" + value + "e";
	};
	var encode_string = function (value) {
		return "" + value.length + ":" + value;
	};
	var encode_list = function (value) {
		var str = [ "l" ],
			i;

		// List values
		for (i = 0; i < value.length; ++i) {
			str.push(encode(value[i]));
		}

		// End
		str.push("e");
		return str.join("");
	};
	var encode_dict = function (value) {
		var str = [ "d" ],
			keys = [],
			i;

		// Get and sort keys
		for (i in value) keys.push(i);
		keys.sort();

		// Push values
		for (i = 0; i < keys.length; ++i) {
			str.push(encode_string(keys[i]));
			str.push(encode(value[keys[i]]));
		}

		// End
		str.push("e");
		return str.join("");
	};



	// Decoding class
	var Decoder = function () {
		this.pos = 0;
	};

	Decoder.prototype = {
		constructor: Decoder,

		decode: function (str) {
			// Errors
			var k = str[this.pos];
			if (!(k in decode_generic)) throw "Invalid format";

			// Call
			return decode_generic[k].call(this, str);
		},
		decode_int: function (str) {
			// Skip the "i" prefix
			++this.pos;

			var end = str.indexOf("e", this.pos),
				value;

			// No end
			if (end < 0) throw "Invalid format";

			// Assume proper number format
			value = parseInt(str.substr(this.pos, end - this.pos), 10);

			// Done
			this.pos = end + 1;
			return value;
		},
		decode_string: function (str) {
			var delim = str.indexOf(":", this.pos),
				length, value;

			// No end
			if (delim < 0) throw "Invalid format";

			// Assume proper number format
			length = parseInt(str.substr(this.pos, delim - this.pos), 10);
			value = str.substr(delim + 1, length);

			// Done
			this.pos = delim + length + 1;
			return value;
		},
		decode_list: function (str) {
			// Skip the "l" prefix
			++this.pos;

			// Read list
			var list = [],
				value;

			// Loop until end or exception
			while (str[this.pos] != "e") {
				value = this.decode(str); // this throws errors if str[this.pos] is out of bounds
				list.push(value);
			}

			// Done; skip "e" suffix
			++this.pos;
			return list;
		},
		decode_dict: function (str) {
			// Skip the "d" prefix
			++this.pos;

			// Read dict
			var dict = {},
				key, value;

			// Loop until end or exception
			while (str[this.pos] != "e") {
				key = this.decode_string(str);
				value = this.decode(str); // this throws errors if str[this.pos] is out of bounds
				dict[key] = value;
			}

			// Done; skip "e" suffix
			++this.pos;
			return dict;
		},
	};

	// Generic decode functions
	var decode_generic = {
			"l": Decoder.prototype.decode_list,
			"d": Decoder.prototype.decode_dict,
			"i": Decoder.prototype.decode_int,
		},
		i;
	for (i = 0; i < 10; ++i) decode_generic[i.toString()] = Decoder.prototype.decode_string;



	// Encode/decode functions
	return {
		/**
			encode: function (obj)
			Encodes an object into a Bencode'd string

			@param obj
				The object to encode
				This should only be one of the following:
					string
					number (floats are floor'd to integers)
					array (containing things only from this list)
					object (containing things only from this list)
				Strings should be encoded in some way such that each character is in the range [0,255]
			@return
				A string representing the object
		*/
		encode: encode,
		/**
			decode: function (str)
			Decodes a Bencode'd string back into its original type

			@param str
				The string to decode
			@return
				The original object represented by str
			@throws
				Any one of the following self-explanatory strings
				"Invalid format"
				"Invalid string"
				"Invalid int"
		*/
		decode: function (str) {
			// Create a decoder and call
			return (new Decoder()).decode(str);
		},
	};

})();


