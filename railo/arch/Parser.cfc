component {

	this.open = ["BEGIN", "PARENOPEN", "BRACKETOPEN", "BRACEOPEN"]
	this.close = ["END", "PARENCLOSE", "BRACKETCLOSE", "BRACECLOSE"]
	this.symbols = ["END", ")", "]", "}"]

	public Struct[] function group(required Struct[] tokens) {

		var nodes = []

		do {
			var token = arguments.tokens.first()
			arguments.tokens.deleteAt(1)

			var index = this.open.find(token.type)
			if (index > 0) {
				token.children = this.group(arguments.tokens)
				if (token.children.isEmpty()) {
					Throw("Premature end of block", "ParseException", "{line: #token.line#, column: #token.column#}");
				} else {
					// The close of the block should be of the same type.
					var closeToken = token.children.last()
					if (close.find(closeToken.type) != index) {
						Throw("Matching #token.lexeme#, expected #this.symbols[index]# but received #closeToken.lexeme#", "ParseException", "{line: #token.line#, column: #token.column#}");
					}
					token.children.delete(closeToken)
				}
			}

			nodes.append(token);

			if (this.close.find(token.type) > 0) {
				break;
			}

		} while (!arguments.tokens.isEmpty());

		return nodes;
	}

}