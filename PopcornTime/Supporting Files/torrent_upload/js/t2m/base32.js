


// Module for encoding/decoding base32
var Base32 = (function () {
	"use strict";

	// Vars used
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567",
		pad_lengths = [ 0, 1, 3, 4, 6 ],
		pad_char = "=";



	// Encode/decode functions
	return {
		/**
			Encode a string into base32

			@param str
				The string to convert.
				This string should be encoded in some way such that each character is in the range [0,255]
			@return
				A base32 encoded string
		*/
		encode: function (str) {
			var len = str.length,
				str_new = "",
				i = 0,
				c1, c2, c3, c4, c5;

			// Null pad
			while ((str.length % 5) !== 0) str += "\x00";

			// String modify
			while (i < len) {
				c1 = str.charCodeAt(i++);
				c2 = str.charCodeAt(i++);
				c3 = str.charCodeAt(i++);
				c4 = str.charCodeAt(i++);
				c5 = str.charCodeAt(i++);

				str_new += alphabet[(c1 >> 3)];
				str_new += alphabet[((c1 & 0x07) << 2) | (c2 >> 6)];
				str_new += alphabet[((c2 & 0x3F) >> 1)];
				str_new += alphabet[((c2 & 0x01) << 4) | (c3 >> 4)];
				str_new += alphabet[((c3 & 0x0F) << 1) | (c4 >> 7)];
				str_new += alphabet[((c4 & 0x7F) >> 2)];
				str_new += alphabet[((c4 & 0x03) << 3) | (c5 >> 5)];
				str_new += alphabet[(c5 & 0x1F)];
			}

			// Padding
			if (i > len) {
				i = pad_lengths[i - len]; // (i - len) equals the number of times \x00 was padded
				str_new = str_new.substr(0, str_new.length - i);
				while ((str_new.length % 8) !== 0) str_new += pad_char;
			}

			// Done
			return str_new;
		},
		/**
			Decode a string from base32

			@param str
				A valid base32 string
			@return
				The original string
		*/
		decode: function (str) {
			var len = str.length,
				str_new = "",
				bits = 0,
				char_buffer = 0,
				i;

			// Cut off padding
			while (len > 0 && str[len - 1] == "=") --len;

			// Iterate
			for (i = 0; i < len; ++i) {
				// Update with the 32bit value
				char_buffer = (char_buffer << 5) | alphabet.indexOf(str[i]);

				// Update bitcount
				bits += 5;
				if (bits >= 8) {
					// Update string
					str_new += String.fromCharCode((char_buffer >> (bits - 8)) & 0xFF);
					bits -= 8;
				}
			}

			// Done
			return str_new;
		},
	};

})();



