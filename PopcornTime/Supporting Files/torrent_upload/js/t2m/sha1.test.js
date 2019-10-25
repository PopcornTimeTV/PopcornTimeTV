


// Functions for testing sha1.js
(function () {
	"use strict";

	// Tests
	var tests = [
		{
			value: "abc",
			repeat: 1,
			correct: "A9 99 3E 36 47 06 81 6A BA 3E 25 71 78 50 C2 6C 9C D0 D8 9D",
		},
		{
			value: "abcdbcdecdefdefgefghfghighijhi" + "jkijkljklmklmnlmnomnopnopq",
			repeat: 1,
			correct: "84 98 3E 44 1C 3B D2 6E BA AE 4A A1 F9 51 29 E5 E5 46 70 F1",
		},
		{
			value: "a",
			repeat: 1000000,
			correct: "34 AA 97 3C D4 C4 DA A4 F6 1E EB 2B DB AD 27 31 65 34 01 6F",
		},
		{
			value: "01234567012345670123456701234567" + "01234567012345670123456701234567",
			repeat: 10,
			correct: "DE A3 56 A2 CD DD 90 C7 A7 EC ED C5 EB B5 63 93 4F 46 04 52",
		},
		{
			value: "a",
			repeat: 133047678,
			correct: "94 A8 41 C9 02 1D 23 57 A8 0A 77 60 01 E2 7D 2F 27 93 91 05",
		},
	];


	// Readable hex
	var digest_to_spaced_hex = function (digest) {
		// String build
		var s = [],
			c, i;

		for (i = 0; i < digest.length; ++i) {
			if (i > 0) s.push(" ");
			c = digest[i].toString(16).toUpperCase();
			if (c.length < 2) s.push("0");
			s.push(c);
		}

		return s.join("");
	};


	// Test function
	var execute_tests = function () {
		// Vars for testing
		var sha = new SHA1(),
			failures = 0,
			test, digest, i, j;

		// Run tests
		for (i = 0; i < tests.length; ++i) {
			test = tests[i];
			console.log("Test " + (i + 1) + ": " + JSON.stringify(test.value) + " repeated " + test.repeat + " time" + (test.repeat == 1 ? "" : "s"));

			sha.reset();

			for (j = 0; j < test.repeat; ++j) {
				sha.update(test.value);
			}

			digest = digest_to_spaced_hex(sha.digest());

			if (digest == test.correct) {
				console.log("Digest matches: YES");
				console.log("  " + digest);
			}
			else {
				console.log("Digest matches: NO");
				console.log("  " + digest + "(calculated)");
				console.log("  " + test.correct + " (correct)");
				++failures;
			}

			console.log("");
		}

		// Final status
		if (failures === 0) {
			console.log("All tests okay");
		}
		else {
			console.log("" + failures + " test" + (failures == 1 ? "" : "s") + " failed");
		}
	};

	execute_tests();

})();


