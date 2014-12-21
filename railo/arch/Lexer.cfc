component {

	public void function init(Numeric tabSpaces = 4) {
		this.tabSpaces = tabSpaces
	}

	public Struct[] function tokenize(required String code) {

		var lines = code.trim().listToArray(Chr(10), true)
		var tokens = [token("BEGIN", "", 0, 0)]
		var line = 1

		// These regexes need to match from the start of each line:
		var indent = pattern("^[ \t]*") // We need to match 0 or more characters.
		var empty = pattern("^\s*$")

		var reserved = {
			// Reserved words or characters:
			BOOLEAN: pattern("^(true|false)"),
			UNDEFINED: pattern("^undefined"),
			INFINITY: pattern("^infinity"),
			// PLACEHOLDER: pattern("^_"),
			IF: pattern("^if"),
			THEN: pattern("^then"),
			ELSE: pattern("^else"),
			BEGIN: pattern("^begin"),
			END: pattern("^end")
		}

		var words = StructNew("linked")
		// Identifiers: function names, variables. This can be a compound identifier, like 'ab' meaning 'a * b'.
		words.IDENTIFIER = pattern("^[A-Za-z]\w*")
		// String literals: anything between double quotes.
		words.STRING = pattern("^""([^""]|"""")*""")
		// Template: a string with % placeholders.
		words.TEMPLATE = pattern("^`([^`]|``)*`")
		// Regex literals: anything between slashes, backslash escapes.
		words.REGEX = pattern("^/([^/]|\\/)*/[gi]?")
		// Number literals:
		words.HEX = pattern("^0x[0-9A-Fa-f]+")
		words.NUMBER = pattern("^\d+(\.\d+)?([Ee]\d+)?") // Including exponential notation.
		// Date and time literals.
		words.TIME = pattern("^'\d{2}:\d{2}(:\d{2}\.\d+)?'")
		words.DATE = pattern("^'\d{4}-\d{2}-\d{2}( \d{2}:\d{2}(:\d{2}\.\d+)?)?'")
		words.CONTINUE = pattern("^:$")
		// Operators: a sequence of one or more of the following characters.
		words.OPERATOR = pattern("^[=~<>+\-*/^\\!:]+")
		// The different types of braces.
		words.PARENOPEN = pattern("^\(")
		words.PARENCLOSE = pattern("^\)")
		words.BRACKETOPEN = pattern("^\[")
		words.BRACKETCLOSE = pattern("^\]")
		words.BRACEOPEN = pattern("^\{")
		words.BRACECLOSE = pattern("^\}")
		// PIPEOPEN: pattern("^\|"),
		// PIPECLOSE: pattern("^\|"),
		// Spaces can be significant. Multiple spaces are treated as one.
		words.SPACE = pattern("^[ ]+")
		words.DELIMITER = pattern("^[,;]")
		// Comment: # followed by anything up to the end of the line.
		words.COMMENT = pattern("^##.*")

		// Words that begin a block implicitly.
		var implicitBegin = ["then", "else", "->"]
		// And words that implicitly end a block.
		var implicitEnd = ["else"]

		var names = reserved.keyArray().append(words.keyArray(), true)
		words.append(reserved)

		lines.each(function (line, index) {
			var number = arguments.index
			var column = 0
			dump(number & ": " & line)
			if (!matches(line, empty)) {
				// First determine the indent depth by counting spaces and tabs.
				column = match(line, indent).listToArray("").reduce(function (sum, char) {
					return sum + (char === " " ? 1 : this.tabSpaces);
				}, 1)

				var chunk = line.trim()

				// Check for implicit block ends.
				implicitEnd.some(function (word) {
					if (chunk.startsWith(arguments.word)) {
						tokens.append(token("END", arguments.word, number, column))
						return true;
					}

					return false;
				})

				while (!chunk.isEmpty()) {
					var consumed = names.some(function (name) {
						var lexeme = match(chunk, words[name])
						if (!lexeme.isEmpty()) {
							tokens.append(token(arguments.name, lexeme, number, column))
							chunk = chunk.removeChars(1, lexeme.len())
							column += lexeme.len()

							return true;
						}

						return false;
					})

					if (!consumed) {
						Throw("Could not match token for chunk: '" & chunk & "'", "ParseException", "{line: #number#, column: #column#}");
					}
				}

				var lastToken = tokens.last()
				if (lastToken.type == "CONTINUE") {
					// Convert to a space and ignore the new line.
					lastToken.type = "SPACE"
				} else if (implicitBegin.find(lastToken.lexeme) > 0) {
					tokens.append(token("BEGIN", "", number, column + 1))
				} else {
					tokens.append(token("NEWLINE", "\n", number, column + 1))
				}

			}

		})

		tokens.append(token("END", "", 0, 0))

		// Filter all new lines that follow BEGIN or COMMENT. All remaining new lines are then statement separators.
		var removeAfter = ["BEGIN", "COMMENT"]
		return tokens.filter(function (token, index) {
			// New lines cannot occur as the first token, because that would imply an empty line, which is filtered out already.
			if (arguments.token.type == "NEWLINE" && removeAfter.find(tokens[arguments.index - 1].type) > 0) {
				return false;
			}

			return true;
		});
	}

	private Any function pattern(required String pattern) {
		return CreateObject("java", "java.util.regex.Pattern").compile(arguments.pattern);
	}

	private Boolean function matches(required String string, required Any pattern) {
		return arguments.pattern.matcher(arguments.string).find();
	}

	private String function match(required String string, required Any pattern) {
		var matcher = arguments.pattern.matcher(arguments.string)
		if (matcher.find()) {
			var start = matcher.start()
			return arguments.string.mid(start + 1, matcher.end() - start);
		}

		return "";
	}

	private Struct function token(required String type, required String lexeme, required Numeric line, required Numeric column) {
		return {
			type: arguments.type,
			lexeme: arguments.lexeme,
			line: arguments.line,
			column: arguments.column
		}
	}

}