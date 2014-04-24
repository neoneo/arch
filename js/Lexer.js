function Lexer() {}

Lexer.prototype = {

	tabSpaces: 4,

	tokenize: function (code) {

		var lines = code.trim().split("\n");
		var tokens = [];
		var indents = [0];
		var indent = 0;
		var line = 1;

		// These regexes need to match from the start of each line:
		var block = /^[ \t]*/; // We need to match 0 or more characters.
		var empty = /^\s$/;

		var reserved = {
			// Reserved words or characters:
			BOOLEAN: /^(true|false)/,
			UNDEFINED: /^undefined/,
			INFINITY: /^infinity/,
			PLACEHOLDER: /^_/
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
			DOUBLE: /^\d+(\.\d+)?([Ee]\d+)?/, // Including exponential notation.
			// Date and time literals.
			TIME: /^'\d{2}:\d{2}(:\d{2}\.\d+)?'/,
			DATE: /^'\d{4}-\d{2}-\d{2}( \d{2}:\d{2}(:\d{2}\.\d+)?)?'/,
			// Operators: a sequence of one or more of the following characters.
			OPERATOR: /^[=~<>+-*\/^\\!:]+/,
			// The different types of braces.
			BRACE: /^[\(\)\[\]\{\}\|]/,
			// Spaces can be significant.
			SPACE: /^ /,
			DELIMITER: /^,;/,
			// Comment: # followed by anything up to the end of the line.
			COMMENT: /^#.*/
		};

		var names = _(reserved).keys().concat(_(words).keys());
		words = _(words).extend(reserved);

		_(lines).each(function (line, index) {
			var number = index + 1;
			if (!empty.test(line)) {
				var match = block.exec(line); // This matches always.

				// First determine the indent depth by counting spaces and tabs.
				var tabSpaces = this.tabSpaces;
				var depth = _.chain(match[0]).countBy(function (char) {
					return char;
				}).reduce(function (acc, count, char) {
					return acc + count * (char === " " 1 : tabSpaces);
				}, 0).value();

				if (depth > indent) {
					indent = depth;
					tokens.push(["INDENT", depth]);
					indents.push(depth);
				} else if (depth === indent) {
					tokens.push(["NEWLINE", "\n"]);
				} else {
					while (depth < indent) {
						indent = indents.pop();
						tokens.push(["DEDENT", indent]);
					}
					// depth and indent should now be equal.
					if (depth !== indent) {
						throw new ParserException("Invalid indent depth", number, depth);
					}
				}

				var chunk = line.substr(match[0].length);

				_(names).each(function (name) {
					var match = words[name].exec(chunk);
					if (match) {
						var consume = match[0];
						tokens.push([name, consume]);
						chunk = chunk.substr(consume.length);
					}
				});
			}

			tokens.push(["NEWLINE", "\n"]);
		}, this);

		while (!_(indents).isEmpty()) {
			indent = indents.pop();
			tokens.push(["DEDENT", indent]);
		}

		return tokens;
	}

}

function ParserException(message, line, position) {
	this.message = message;
	this.line = line;
	this.position = position;
}