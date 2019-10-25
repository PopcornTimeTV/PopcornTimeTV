


// Class for SHA1 computation
var SHA1 = (function () {
	"use strict";

	// Private variables
	var hash_size = 20,
		message_block_length = 64,
		message_block_terminator = 0x80,
		message_length_bytes = 8,
		initial_intermediate_hash = new Uint32Array(5),
		K_constants = new Uint32Array(4);

	initial_intermediate_hash[0] = 0x67452301;
	initial_intermediate_hash[1] = 0xEFCDAB89;
	initial_intermediate_hash[2] = 0x98BADCFE;
	initial_intermediate_hash[3] = 0x10325476;
	initial_intermediate_hash[4] = 0xC3D2E1F0;

	K_constants[0] = 0x5A827999;
	K_constants[1] = 0x6ED9EBA1;
	K_constants[2] = 0x8F1BBCDC;
	K_constants[3] = 0xCA62C1D6;



	/**
		SHA1 instance constructor; creates an empty SHA1 object.

		@return
			A new SHA1 instance
	*/
	var SHA1 = function () {
		this.length = 0;
		this.message_block_index = 0;
		this.message_block = new Uint8Array(message_block_length);
		this.intermediate_hash = new Uint32Array(initial_intermediate_hash);
	};



	// Private methods
	var pad = function () {
		var maxlen = this.message_block.length - message_length_bytes,
			high = Math.floor(this.length / 0x0FFFFFFFF) & 0xFFFFFFFF,
			low = this.length & 0xFFFFFFFF,
			message_block = this.message_block,
			message_block_index = this.message_block_index,
			input_intermediate_hash = this.intermediate_hash,
			output_intermediate_hash = new Uint32Array(this.intermediate_hash.length);

		// Termination byte
		message_block[message_block_index] = message_block_terminator;

		// Process another block if there's no space for the length
		if (message_block_index >= maxlen) {
			// 0-ify
			while (++message_block_index < message_block.length) message_block[message_block_index] = 0;

			// Process block
			process.call(this, message_block, input_intermediate_hash, output_intermediate_hash);

			// Create copies that don't interfere with "this"
			message_block = new Uint8Array(message_block.length); // no 0-ifying needed
			input_intermediate_hash = output_intermediate_hash;
		}
		else {
			// 0-ify
			while (++message_block_index < maxlen) message_block[message_block_index] = 0;
		}

		// Store length
		message_block[maxlen] = (high >>> 24) & 0xFF;
		message_block[++maxlen] = (high >>> 16) & 0xFF;
		message_block[++maxlen] = (high >>> 8) & 0xFF;
		message_block[++maxlen] = (high) & 0xFF;
		message_block[++maxlen] = (low >>> 24) & 0xFF;
		message_block[++maxlen] = (low >>> 16) & 0xFF;
		message_block[++maxlen] = (low >>> 8) & 0xFF;
		message_block[++maxlen] = (low) & 0xFF;

		process.call(this, message_block, input_intermediate_hash, output_intermediate_hash);

		// Return hash
		return output_intermediate_hash;
	};
	var process = function (message_block, intermediate_hash_input, intermediate_hash_output) {
		var W = new Uint32Array(80),
			i, i4, temp, A, B, C, D, E;

		// Init W
		for (i = 0; i < 16; ++i) {
			i4 = i * 4;
			W[i] =
				(message_block[i4] << 24) |
				(message_block[i4 + 1] << 16) |
				(message_block[i4 + 2] << 8) |
				(message_block[i4 + 3]);
		}
		for (/*i = 16*/; i < 80; ++i) {
			W[i] = circular_shift(1, W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16]);
		}

		A = intermediate_hash_input[0];
		B = intermediate_hash_input[1];
		C = intermediate_hash_input[2];
		D = intermediate_hash_input[3];
		E = intermediate_hash_input[4];

		for (i = 0; i < 20; ++i) {
			temp = circular_shift(5, A) + ((B & C) | ((~B) & D)) + E + W[i] + K_constants[0];
			E = D;
			D = C;
			C = circular_shift(30, B);
			B = A;
			A = temp & 0xFFFFFFFF;
		}
		for (/*i = 20*/; i < 40; ++i) {
			temp = circular_shift(5, A) + (B ^ C ^ D) + E + W[i] + K_constants[1];
			E = D;
			D = C;
			C = circular_shift(30, B);
			B = A;
			A = temp & 0xFFFFFFFF;
		}
		for (/*i = 40*/; i < 60; ++i) {
			temp = circular_shift(5, A) + ((B & C) | (B & D) | (C & D)) + E + W[i] + K_constants[2];
			E = D;
			D = C;
			C = circular_shift(30, B);
			B = A;
			A = temp & 0xFFFFFFFF;
		}
		for (/*i = 60*/; i < 80; ++i) {
			temp = circular_shift(5, A) + (B ^ C ^ D) + E + W[i] + K_constants[3];
			E = D;
			D = C;
			C = circular_shift(30, B);
			B = A;
			A = temp & 0xFFFFFFFF;
		}

		intermediate_hash_output[0] = intermediate_hash_input[0] + A;
		intermediate_hash_output[1] = intermediate_hash_input[1] + B;
		intermediate_hash_output[2] = intermediate_hash_input[2] + C;
		intermediate_hash_output[3] = intermediate_hash_input[3] + D;
		intermediate_hash_output[4] = intermediate_hash_input[4] + E;
	};
	var circular_shift = function (bits, word) {
		return (word << bits) | (word >>> (32 - bits));
	};



	// Public methods
	SHA1.prototype = {
		constructor: SHA1,

		/**
			Reset the state of the hashing object to its initial state.
		*/
		reset: function () {
			// Reset everything
			var i;

			this.length = 0;
			this.message_block_index = 0;

			for (i = 0; i < this.intermediate_hash.length; ++i) {
				this.intermediate_hash[i] = initial_intermediate_hash[i];
			}
			for (i = 0; i < this.message_block.length; ++i) {
				this.message_block[i] = 0;
			}
		},

		/**
			Feed data into the instance to update the hash.

			@param value_array
				The values to update with. This can either be:
					- A string (encoded so that every character is in the range [0,255])
					- A (typed) array
		*/
		update: function (value_array) {
			var is_string = (typeof(value_array) == "string"),
				i;

			for (i = 0; i < value_array.length; ++i) {
				// Update block
				this.message_block[this.message_block_index] = is_string ? value_array.charCodeAt(i) : value_array[i];

				// Update length
				this.length += 8;

				// Process block
				if (++this.message_block_index >= this.message_block.length) {
					process.call(this, this.message_block, this.intermediate_hash, this.intermediate_hash);
					this.message_block_index = 0;
				}
			}
		},

		/**
			Computes the SHA1 digest of the data input so far.

			@return
				A Uint8Array of the computed digest
		*/
		digest: function () {
			// Setup
			var digest = new Uint8Array(hash_size),
				intermediate_hash_temp = pad.call(this),
				i;

			// Hash
			for (i = 0; i < digest.length; ++i) {
				digest[i] = intermediate_hash_temp[i >> 2] >> (8 * (3 - (i & 0x03)));
			}

			// Done
			return digest;
		},
	};



	// Return the class object
	return SHA1;

})();


