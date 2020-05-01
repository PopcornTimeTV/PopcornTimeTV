
// all thanks to 
// https://github.com/nutbread/t2m

var T2M = (function () {
	"use strict";

	// Module for encoding/decoding UTF8
	var UTF8 = (function () {

		return {
			/**
				Encode a string into UTF-8

				@param str
					The string to convert.
					This string should be encoded in some way such that each character is in the range [0,255]
				@return
					A UTF-8 encoded string
			*/
			encode: function (str) {
				return unescape(encodeURIComponent(str));
			},
			/**
				Decode a string from UTF-8

				@param str
					A valid UTF-8 string
				@return
					The original string
			*/
			decode: function (str) {
				return decodeURIComponent(escape(str));
			},
		};

	})();



	// Class for reading .torrent files
	var Torrent = (function () {

		var Torrent = function () {
			this.events = {
				"load": [],
				"error": [],
				"read_error": [],
				"read_abort": [],
			};
			this.file_name = null;
			this.data = null;
		};



		var on_reader_load = function (event) {
			// Decode
			var data_str = event.target.result;

			if (data_str instanceof ArrayBuffer) {
				// Convert to string
				var data_str2 = "",
					i;

				data_str = new Uint8Array(data_str);
				for (i = 0; i < data_str.length; ++i) {
					data_str2 += String.fromCharCode(data_str[i]);
				}

				data_str = data_str2;
			}

			try {
				this.data = Bencode.decode(data_str);
			}
			catch (e) {
				// Throw an error
				this.data = null;
				this.file_name = null;
				trigger.call(this, "error", {
					type: "Bencode error",
					exception: e,
				});
				return;
			}

			// Loaded
			trigger.call(this, "load", {});
		};
		var on_reader_error = function () {
			trigger.call(this, "read_error", {});
		};
		var on_reader_abort = function () {
			trigger.call(this, "read_abort", {});
		};
		var trigger = function (event, data) {
			// Trigger an event
			var callbacks = this.events[event],
				i;

			for (i = 0; i < callbacks.length; ++i) {
				callbacks[i].call(this, data, event);
			}
		};
		var no_change = function (x) {
			return x;
		};

		var magnet_component_order_default = [ "xt" , "xl" , "dn" , "tr" ];

		var format_uri = function (array_values, encode_fcn) {
			if (array_values.length <= 1) return encode_fcn(array_values[0]);

			return array_values[0].replace(/\{([0-9]+)\}/, function (match) {
				return encode_fcn(array_values[parseInt(match[1], 10) + 1] || "");
			});
		};



		/**
			Convert URI components object into a magnet URI.
			This is used to format the same object multiple times without rehashing anything.

			@param link_components
				An object returned from convert_to_magnet with return_components=true
			@param custom_name
				Can take one of the following values:
					null/undefined: name will remain the same as it originally was
					string: the custom name to give the magnet URI
			@param tracker_mode
				Can take one of the following values:
					null/undefined/false/number < 0: single tracker only (primary one)
					true: multiple trackers (without numbered suffix)
					number >= 0: multiple trackers (with numbered suffix starting at the specified number)
			@param uri_encode
				Can take one of the following values:
					null/undefined/true: encode components using encodeURIComponent
					false: no encoding; components are left as-is
					function: custom encoding function
			@param component_order
				A list containing the order URI components should appear in.
				Default is [ "xt" , "xl" , "dn" , "tr" ]
				null/undefined will use the default
			@return
				A formatted URI
		*/
		Torrent.components_to_magnet = function (link_components, custom_name, tracker_mode, uri_encode, component_order) {
			// Vars
			var link, obj, list1, val, i, j;

			uri_encode = (uri_encode === false) ? no_change : (typeof(uri_encode) == "function" ? uri_encode : encodeURIComponent);
			component_order = (component_order === null) ? magnet_component_order_default : component_order;

			// Setup
			if (typeof(custom_name) == "string") {
				link_components.dn.values = [ custom_name ];
			}

			link_components.tr.suffix = -1;
			if (typeof(tracker_mode) == "number") {
				tracker_mode = Math.floor(tracker_mode);
				if (tracker_mode >= 0) link_components.tr.suffix = tracker_mode;
			}
			else if (tracker_mode === true) {
				link_components.tr.suffix = -2;
			}

			// Form into a URL
			link = "magnet:";
			val = 0; // number of components added
			for (i = 0; i < component_order.length; ++i) {
				if (!(component_order[i] in link_components)) continue; // not valid
				obj = link_components[component_order[i]];
				list1 = obj.values;
				for (j = 0; j < list1.length; ++j) {
					// Separator
					link += (val === 0 ? "?" : "&");
					++val;

					// Key
					link += component_order[i];

					// Number
					if (obj.suffix >= 0 && list1.length > 1) {
						link += ".";
						link += obj.suffix;
						++obj.suffix;
					}

					// Value
					link += "=";
					link += format_uri(list1[j], uri_encode);

					// Done
					if (obj.suffix == -1) break;
				}
			}

			// Done
			return link;
		};



		Torrent.prototype = {
			constructor: Torrent,

			read: function (file) {
				this.data = null;
				this.file_name = file.name;

				var reader = new FileReader();

				reader.addEventListener("load", on_reader_load.bind(this), false);
				reader.addEventListener("error", on_reader_error.bind(this), false);
				reader.addEventListener("abort", on_reader_abort.bind(this), false);

				try {
					reader.readAsBinaryString(file);
				}
				catch (e) {
					reader.readAsArrayBuffer(file);
				}
			},

			on: function (event, callback) {
				if (event in this.events) {
					this.events[event].push(callback);
					return true;
				}
				return false;
			},
			off: function (event, callback) {
				if (event in this.events) {
					var callbacks = this.events[event],
						i;

					for (i = 0; i < callbacks.length; ++i) {
						if (callbacks[i] == callback) {
							callbacks.splice(i, 1);
							return true;
						}
					}
				}
				return false;
			},

			/**
				Convert the torrent data into a magnet link.

				@param custom_name
					Can take one of the following values:
						null/undefined: no custom name will be generated, but if the name field is absent, it will be assumed from the original file's name
						false: no custom name will be generated OR assumed from the original file name
						string: the custom name to give the magnet URI
				@param tracker_mode
					Can take one of the following values:
						null/undefined/false/number < 0: single tracker only (primary one)
						true: multiple trackers (without numbered suffix)
						number >= 0: multiple trackers (with numbered suffix starting at the specified number)
				@param uri_encode
					Can take one of the following values:
						null/undefined/true: encode components using encodeURIComponent
						false: no encoding; components are left as-is
						function: custom encoding function
				@param component_order
					A list containing the order URI components should appear in.
					Default is [ "xt" , "xl" , "dn" , "tr" ]
					null/undefined will use the default
				@param return_components
					If true, this returns the link components which can then be used with components_to_magnet
				@return
					A formatted URI if return_components is falsy, else an object containing the parts of the link
					Also can return null if insufficient data is found
			*/
			convert_to_magnet: function (custom_name, tracker_mode, uri_encode, component_order, return_components) {
				// Insufficient data
				if (this.data === null || !("info" in this.data)) return null;

				// Bencode info
				var info = this.data.info,
					info_bencoded = Bencode.encode(info),
					info_hasher = new SHA1(),
					link_components = {},
					info_hash, link, list1, list2, val, i, j;

				// Hash
				info_hasher.update(info_bencoded);
				info_hash = info_hasher.digest();
				info_hash = String.fromCharCode.apply(null, info_hash); // convert to binary string
				info_hash = Base32.encode(info_hash); // convert to base32

				// Setup link
				for (i = 0; i < magnet_component_order_default.length; ++i) {
					link_components[magnet_component_order_default[i]] = {
						suffix: -1,
						values: [],
					};
				}

				// Create
				link_components.xt.values.push([ "urn:btih:{0}", info_hash ]);

				if ("length" in info) {
					link_components.xl.values.push([ info.length ]);
				}

				if (typeof(custom_name) == "string") {
					link_components.dn.values.push([ custom_name ]);
				}
				else if ("name" in info) {
					link_components.dn.values.push([ UTF8.decode(info.name) ]);
				}
				else if (custom_name !== false && this.file_name) {
					link_components.dn.values.push([ this.file_name ]);
				}

				list1 = link_components.tr.values;
				if ("announce" in this.data) {
					list1.push([ UTF8.decode(this.data.announce) ]);
				}
				if ("announce-list" in this.data && Array.isArray(list2 = this.data["announce-list"])) {
					// Add more trackers
					for (i = 0; i < list2.length; ++i) {
						if (!Array.isArray(list2[i])) continue; // bad data
						for (j = 0; j < list2[i].length; ++j) {
							val = UTF8.decode(list2[i][j]);
							if (list1.indexOf(val) < 0) list1.push([ val ]);
						}
					}
				}

				// Convert
				if (return_components) return link_components;
				link = Torrent.components_to_magnet(link_components, null, tracker_mode, uri_encode, component_order);

				// Done
				return link;
			},
		};



		return Torrent;

	})();



	// Class for enumerating the results in the DOM
	var Result = (function () {

		var Result = function () {
			this.torrent_magnet_components = null;
			this.container = null;
			this.magnet_textbox = null;
		};

		var on_textbox_update = function () {
			// Get value
			var uri = this.magnet_textbox.value,
				protocol = "magnet:";

			// Must have correct protocol
			if (uri.substr(0, protocol.length).toLowerCase() != protocol) {
				if (uri.length < protocol.length && uri.toLowerCase() == protocol.substr(0, uri.length)) {
					// Almost correct
					uri += protocol.substr(uri.length);
				}
				else {
					// Wrong
					uri = protocol + uri;
				}
			}
		};

		var on_option_change = function () {
			update_links.call(this, true);
		};

		var update_links = function (update_displays) {
			// Update magnet links
			var magnet_uri = "magnet:asdf",
				tracker_mode = false,
				order = [ "xt","dn","xl","tr" ];
				tracker_mode = true;

			magnet_uri = Torrent.components_to_magnet(this.torrent_magnet_components, null, tracker_mode, true, order);

			// // Update text/values
			this.magnet_textbox.value = magnet_uri;
		};



		Result.prototype = {
			constructor: Result,

			generate: function (torrent_object, parent_node) {
				this.magnet_textbox = document.querySelector("#input_942");

				// // Data
				this.torrent_magnet_components = torrent_object.convert_to_magnet(null, false, true, null, true);
				update_links.call(this, false);
			},
			update: function () {

			},
		};



		return Result;

	})();



	// Other functions
	var rice_checkboxes = null;
	var on_torrent_load = function () {
		var result = new Result();
		result.generate(this, null);
	};



	// Exposed functions
	var functions = {
		setup: function (rice_checkboxes_import) {

		},
		queue_torrent_files: function (files) {
			// Read files
			var i, t;

			for (i = 0; i < files.length; ++i) {
				t = new Torrent();
				t.on("load", on_torrent_load);
				t.read(files[i]);
			}
		},
	};

	return functions;

})();


