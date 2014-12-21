var Class = require("./Class.js");
var _ = require("lodash");

function ParseException(message, line, column) {
	this.message = message;
	this.line = line;
	this.column = column;
}

var Lexer = Class.extend({

	constructor: function (tabSpaces) {
		this.tabSpaces = tabSpaces;
	},

	tokenize: function (code) {

		var TYPE = 0, SYMBOL = 1, LINE = 3, COLUMN = 4;

		var lines = code.trim().split("\n");
		var tokens = [];
		var line = 1;

		// These regexes need to match from the start of each line:
		var block = /^[ \t]*/; // We need to match 0 or more characters.
		var empty = /^\s*$/;

		var reserved = {
			// Reserved words or characters:
			BOOLEAN: /^(true|false)/,
			UNDEFINED: /^undefined/,
			INFINITY: /^infinity/,
			PLACEHOLDER: /^_/,
			IF: /^if/,
			THEN: /^then/,
			ELSE: /^else/,
			BEGIN: /^begin/,
			END: /^end/
		};

		var words = {
			// Identifiers: function names, variables. This can be a compound identifier, like 'ab' meaning 'a * b'.
			IDENTIFIER: /^[A-Za-z]\w*/,
			// String literals: anything between double quotes.
			STRING: /^"([^"]|"")*"/,
			// Template: a string with % placeholders.
			TEMPLATE: /^`([^`]|``)*`/,
			// Regex literals: anything between slashes, backslash escapes.
			REGEX: /^\/([^\/\\]*(\\\/|\\)*)*\//,
			// Number literals:
			HEX: /^0x[0-9A-Fa-f]+/,
			NUMBER: /^\d+(\.\d+)?([Ee]\d+)?/, // Including exponential notation.
			// Date and time literals.
			TIME: /^'\d{2}:\d{2}(:\d{2}\.\d+)?'/,
			DATE: /^'\d{4}-\d{2}-\d{2}( \d{2}:\d{2}(:\d{2}\.\d+)?)?'/,
			// Operators: a sequence of one or more of the following characters.
			OPERATOR: /^[=~<>+\-*\/^\\!:]+/,
			// The different types of braces.
			BRACE: /^[\(\)\[\]\{\}\|]/,
			// Spaces can be significant. Multiple spaces are treated as one.
			SPACE: /^[ ]+/,
			DELIMITER: /^,;/,
			// Comment: # followed by anything up to the end of the line.
			COMMENT: /^#.*/
		};

		// Words that begin a block implicitly.
		var implicitBegin = ["then", "else", "->"]
		// And words that implicitly end a block.
		var implicitEnd = ["else"];

		var names = _.keys(reserved).concat(_.keys(words));
		words = _.extend(words, reserved);

		_.each(lines, function (line, index) {
			var number = index + 1;
			var column = 0;
			if (!empty.test(line)) {
				console.log(line);
				var match = block.exec(line); // This matches always.

				// First determine the indent depth by counting spaces and tabs.
				var tabSpaces = this.tabSpaces;
				var column = _.chain(match[0]).countBy(function (char) {
					return char;
				}).reduce(function (acc, count, char) {
					return acc + count * (char === " " ? 1 : tabSpaces);
				}, 0).value();

				var chunk = line.substr(match[0].length).trim();

				// Check for implicit block ends.
				if (_.some(implicitEnd, function (word) {
					return chunk.indexOf(word) === 0;
				})) {
					tokens.push(["END", "", number, column]);
				}

				while (chunk.length) {
					var consumed = _.some(names, function (name) {
						var match = words[name].exec(chunk);
						if (match) {
							var consume = match[0];
							tokens.push([name, consume, number, column]);
							chunk = chunk.substr(consume.length);
							column += consume.length;

							return true;
						}

						return false;
					});

					if (!consumed) {
						throw new ParserException("Could not match token for chunk: " + chunk, number, column);
					}
				}
			}

			var lastToken = _.last(tokens);
			tokens.push(["NEWLINE", "\n", number, line.length]);

			// Test for implicit begins against the last token (the actual consumed string).
			if (_.indexOf(implicitBegin, lastToken[SYMBOL]) > -1) {
				tokens.push(["BEGIN", "", number, line.length]);
			}
		}, this);

		return tokens;
	}

});

module.exports = Lexer;