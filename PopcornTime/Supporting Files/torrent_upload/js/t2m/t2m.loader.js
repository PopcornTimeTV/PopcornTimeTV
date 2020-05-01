


(function () {
	"use strict";

	// Function for performing actions as soon as possible
	var on_ready = (function () {

		// Vars
		var callbacks = [],
			check_interval = null,
			check_interval_time = 250;

		// Check if ready and run callbacks
		var callback_check = function () {
			if (
				(document.readyState === "interactive" || document.readyState === "complete") &&
				callbacks !== null
			) {
				// Run callbacks
				var cbs = callbacks,
					cb_count = cbs.length,
					i;

				// Clear
				callbacks = null;

				for (i = 0; i < cb_count; ++i) {
					cbs[i].call(null);
				}

				// Clear events and checking interval
				window.removeEventListener("load", callback_check, false);
				window.removeEventListener("readystatechange", callback_check, false);

				if (check_interval !== null) {
					clearInterval(check_interval);
					check_interval = null;
				}

				// Okay
				return true;
			}

			// Not executed
			return false;
		};

		// Listen
		window.addEventListener("load", callback_check, false);
		window.addEventListener("readystatechange", callback_check, false);

		// Callback adding function
		return function (cb) {
			if (callbacks === null) {
				// Ready to execute
				cb.call(null);
			}
			else {
				// Delay
				callbacks.push(cb);

				// Set a check interval
				if (check_interval === null && callback_check() !== true) {
					check_interval = setInterval(callback_check, check_interval_time);
				}
			}
		};

	})();



	// Functions
	var script_add = (function () {

		var script_on_load = function (state) {
			// Okay
			script_remove_event_listeners.call(this, state, true);
		};
		var script_on_error = function (state) {
			// Error
			script_remove_event_listeners.call(this, state, false);
		};
		var script_on_readystatechange = function (state) {
			if (this.readyState === "loaded" || this.readyState === "complete") {
				// Okay
				script_remove_event_listeners.call(this, state, true);
			}
		};
		var script_remove_event_listeners = function (state, okay) {
			// Remove event listeners
			this.addEventListener("load", state.on_load, false);
			this.addEventListener("error", state.on_error, false);
			this.addEventListener("readystatechange", state.on_readystatechange, false);

			state.on_load = null;
			state.on_error = null;
			state.on_readystatechange = null;

			// Trigger
			if (state.callback) state.callback.call(null, okay, this);

			// Remove
			var par = this.parentNode;
			if (par) par.removeChild(this);
		};



		return function (url, callback) {
			var head = document.head,
				script, state;

			if (!head) {
				// Callback and done
				callback.call(null, false, null);
				return false;
			}

			// Load state
			state = {
				on_load: null,
				on_error: null,
				on_readystatechange: null,
				callback: callback,
			};

			// New script tag
			script = document.createElement("script");
			script.async = true;
			script.setAttribute("src", url);

			// Events
			script.addEventListener("load", (state.on_load = script_on_load.bind(script, state)), false);
			script.addEventListener("error", (state.on_error = script_on_error.bind(script, state)), false);
			script.addEventListener("readystatechange", (state.on_readystatechange = script_on_readystatechange.bind(script, state)), false);

			// Add
			head.appendChild(script);

			// Done
			return true;
		};

	})();

	var on_generic_stop_propagation = function (event) {
		event.stopPropagation();
	};

	var on_exclusive_mode_change = function (flag_node) {
		exclusive_mode_update.call(this, flag_node, false);
	};
	var exclusive_mode_update = (function () {
		var previous_fragment = "";

		return function (flag_node, check_fragment) {
			var hash_is_exclusive = (window.location.hash == "#converter.exclusive");

			if (check_fragment) {
				this.checked = hash_is_exclusive;
			}
			else {
				if (this.checked ^ (!hash_is_exclusive)) {
					previous_fragment = window.location.hash;
				}
				window.history.replaceState({}, "", window.location.pathname + (this.checked ? "#converter.exclusive" : previous_fragment));
			}

			if (this.checked) {
				flag_node.classList.add("exclusive_enabled");
			}
			else {
				flag_node.classList.remove("exclusive_enabled");
			}
		};
	})();

	var on_converter_click = function (converter_files_input, event) {
		if (event.which != 2 && event.which != 3) {
			converter_files_input.click();
		}
	};
	var on_converter_files_change = function (converter) {
		// Read
		on_converter_test_files.call(converter, this.files);

		// Nullify
		this.value = null;
	};

	var on_file_dragover = function (converter, event) {
		if (Array.prototype.indexOf.call(event.dataTransfer.types, "Files") < 0) return;

		converter.classList.add("converter_files_active");
		if (this === converter) converter.classList.add("converter_files_hover");

		event.dataTransfer.dropEffect = "copy";
		event.preventDefault();
		event.stopPropagation();
		return false;
	};
	var on_file_dragleave = function (converter, event) {
		if (Array.prototype.indexOf.call(event.dataTransfer.types, "Files") < 0) return;

		converter.classList.remove("converter_files_hover");
		if (this !== converter) converter.classList.remove("converter_files_active");

		event.preventDefault();
		event.stopPropagation();
		return false;
	};
	var on_file_drop = function (converter, event) {
		// Reset style
		converter.classList.remove("converter_files_active");
		converter.classList.remove("converter_files_hover");
		event.preventDefault();
		event.stopPropagation();

		// Not over the converter
		if (this !== converter) return false;

		// Read files
		on_converter_test_files.call(converter, event.dataTransfer.files);

		// Done
		return false;
	};

	var on_converter_test_files = function (files) {
		// Read
		var re_ext = /(\.[^\.]*|)$/,
			read_files = [],
			ext, i;

		for (i = 0; i < files.length; ++i) {
			ext = re_ext.exec(files[i].name)[1].toLowerCase();
			if (ext == ".torrent") {
				read_files.push(files[i]);
			}
		}

		// Nothing to do
		if (read_files.length === 0) return;

		// Load scripts if necessary
		load_requirements(function (errors) {
			if (errors === 0) {
				// Load
				var T2M_obj;
				try {
					T2M_obj = T2M;
				}
				catch(e) {
					return; // not found
				}
				T2M_obj.queue_torrent_files(read_files);
			}
		});
	};

	var load_requirements = (function () {

		// Script requirements
		var requirements = [
			"./js/t2m/sha1.js",
			"./js/t2m/bencode.js",
			"./js/t2m/base32.js",
			"./js/t2m/t2m.js",
		];


		var on_all_scripts_loaded = function () {
			var T2M_obj;
			try {
				T2M_obj = T2M;
			}
			catch(e) {
				return; // not found
			}

			T2M_obj.setup(null);
		};
		var on_script_load = function (state, callback, okay) {
			if (okay) ++state.okay;

			if (++state.count >= state.total) {
				// All loaded/errored
				if (state.total - state.okay === 0) on_all_scripts_loaded();
				callback.call(null, state.total - state.okay);
			}
		};

		// Return the loading function
		return function (callback) {
			// Already loaded?
			if (requirements === null) {
				// Yes
				callback.call(null, 0);
				return;
			}

			var head = document.head,
				on_load, i;

			if (!head) return false;

			// Load
			on_load = on_script_load.bind(null, { okay: 0, count: 0, total: requirements.length, }, callback);
			for (i = 0; i < requirements.length; ++i) {
				script_add(requirements[i], on_load);
			}

			// Done
			requirements = null;
			return true;
		};

	})();


	// Execute
	on_ready(function () {
		// Noscript
		var nodes, i;

		// // Rice
		// restyle_noscript();
		// rice_checkboxes();

		// Stop propagation links
		nodes = document.querySelectorAll(".link_stop_propagation");
		for (i = 0; i < nodes.length; ++i) {
			nodes[i].addEventListener("click", on_generic_stop_propagation, false);
		}

		// Setup converter
		var converter = document.querySelector(".converter"),
			converter_files = document.querySelector(".converter_files_input"),
			exclusive_mode = document.querySelector("input.converter_exclusive_mode_check"),
			non_exclusive_body = document.querySelector(".non_exclusive"),
			body = document.body;

		if (converter !== null) {
			// File browser
			if (converter_files !== null) {
				converter.addEventListener("click", on_converter_click.bind(converter, converter_files), false);
				converter_files.addEventListener("change", on_converter_files_change.bind(converter_files, converter), false);
			}

			// File drag/drop events
			converter.addEventListener("dragover", on_file_dragover.bind(converter, converter), false);
			converter.addEventListener("dragleave", on_file_dragleave.bind(converter, converter), false);
			converter.addEventListener("drop", on_file_drop.bind(converter, converter), false);

			body.addEventListener("dragover", on_file_dragover.bind(body, converter), false);
			body.addEventListener("dragleave", on_file_dragleave.bind(body, converter), false);
			body.addEventListener("drop", on_file_drop.bind(body, converter), false);

			// Exclusive
			if (exclusive_mode !== null) {
				exclusive_mode_update.call(exclusive_mode, non_exclusive_body, true);
				exclusive_mode.addEventListener("change", on_exclusive_mode_change.bind(exclusive_mode, non_exclusive_body), false);
			}
		}
	});

})();


